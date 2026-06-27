"""
Project Sentinel — Feature Engineering Pipeline
Phase 5: Behavioral Analytics + Phase 7: Python Analytics

Builds 100+ behavioral features from raw transaction, GPS,
device, and session data for the Feature Store.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from scipy import stats
from sklearn.preprocessing import StandardScaler
from typing import Optional


class DriverFeatureEngine:
    """
    Computes behavioral features for driver fraud detection.
    Features are grouped into 5 categories:
    1. Route & GPS features
    2. Temporal & session features
    3. Financial & incentive features
    4. Device & identity features
    5. Network & social features
    """

    def __init__(self, lookback_days: int = 30):
        self.lookback_days = lookback_days
        self.feature_registry = {}

    # =========================================================
    # CATEGORY 1: ROUTE & GPS FEATURES
    # =========================================================

    def route_entropy(self, gps_df: pd.DataFrame, driver_id: str) -> float:
        """
        Measures geographic diversity of driver's routes.
        Low entropy = highly repetitive routes (possible fake delivery pattern).
        High entropy = diverse routes (normal delivery behavior).

        Formula: H = -sum(p_i * log2(p_i))
        where p_i = probability of visiting geographic cell i
        """
        driver_gps = gps_df[gps_df['driver_id'] == driver_id].copy()
        if len(driver_gps) < 10:
            return np.nan

        # Quantize GPS to 0.01 degree cells (~1km)
        driver_gps['lat_cell'] = (driver_gps['latitude'] / 0.01).astype(int)
        driver_gps['lng_cell'] = (driver_gps['longitude'] / 0.01).astype(int)
        driver_gps['cell'] = driver_gps['lat_cell'].astype(str) + '_' + driver_gps['lng_cell'].astype(str)

        cell_counts = driver_gps['cell'].value_counts(normalize=True)
        entropy = -np.sum(cell_counts * np.log2(cell_counts + 1e-9))
        return round(float(entropy), 4)

    def gps_consistency_score(self, gps_df: pd.DataFrame, driver_id: str) -> float:
        """
        Measures how consistently a driver's GPS signal flows
        (no teleportation, realistic speeds, no mockGPS indicators).
        Returns score 0-1, where 1 = perfectly consistent.
        """
        driver_gps = gps_df[
            (gps_df['driver_id'] == driver_id) &
            (gps_df['is_mocked'] == False)
        ].sort_values('recorded_at')

        if len(driver_gps) < 5:
            return np.nan

        # Calculate speed between consecutive points
        driver_gps = driver_gps.copy()
        driver_gps['prev_lat'] = driver_gps['latitude'].shift(1)
        driver_gps['prev_lng'] = driver_gps['longitude'].shift(1)
        driver_gps['prev_time'] = driver_gps['recorded_at'].shift(1)

        driver_gps['elapsed_sec'] = (
            pd.to_datetime(driver_gps['recorded_at']) -
            pd.to_datetime(driver_gps['prev_time'])
        ).dt.total_seconds()

        # Haversine distance (vectorized approximation)
        lat_diff = np.radians(driver_gps['latitude'] - driver_gps['prev_lat'])
        lng_diff = np.radians(driver_gps['longitude'] - driver_gps['prev_lng'])
        a = (np.sin(lat_diff / 2) ** 2 +
             np.cos(np.radians(driver_gps['prev_lat'])) *
             np.cos(np.radians(driver_gps['latitude'])) *
             np.sin(lng_diff / 2) ** 2)
        driver_gps['dist_km'] = 6371 * 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))

        driver_gps['speed_kmh'] = driver_gps['dist_km'] / (driver_gps['elapsed_sec'] / 3600 + 1e-9)

        # Penalize impossible speeds (>150 km/h delivery vehicle)
        impossible_speed_pct = (driver_gps['speed_kmh'] > 150).mean()
        consistency_score = 1.0 - min(impossible_speed_pct * 5, 1.0)  # Scale penalty
        return round(float(consistency_score), 4)

    def delivery_clustering_score(self, orders_df: pd.DataFrame, driver_id: str) -> float:
        """
        Detects if a driver's deliveries are suspiciously clustered
        in a tiny geographic area (indicative of fake pickup/delivery).
        Returns normalized variance of delivery coordinates.
        """
        driver_orders = orders_df[
            (orders_df['driver_id'] == driver_id) &
            (orders_df['delivery_lat'].notna())
        ]

        if len(driver_orders) < 5:
            return np.nan

        lat_std = driver_orders['delivery_lat'].std()
        lng_std = driver_orders['delivery_lng'].std()
        spread = np.sqrt(lat_std ** 2 + lng_std ** 2)

        # Very low spread = suspicious clustering
        return round(float(spread), 6)

    # =========================================================
    # CATEGORY 2: TEMPORAL & SESSION FEATURES
    # =========================================================

    def acceptance_latency_stats(self, orders_df: pd.DataFrame, driver_id: str) -> dict:
        """
        Analyzes time between order assignment and acceptance.
        Bots/scripts accept orders near-instantly (<2 seconds).
        Returns mean, std, min, and suspicious_rate.
        """
        driver_orders = orders_df[
            (orders_df['driver_id'] == driver_id) &
            (orders_df['order_accepted_at'].notna())
        ].copy()

        if len(driver_orders) < 5:
            return {'acceptance_latency_mean': np.nan,
                    'acceptance_latency_std': np.nan,
                    'acceptance_bot_rate': np.nan}

        driver_orders['latency_sec'] = (
            pd.to_datetime(driver_orders['order_accepted_at']) -
            pd.to_datetime(driver_orders['order_placed_at'])
        ).dt.total_seconds()

        latency_mean = driver_orders['latency_sec'].mean()
        latency_std = driver_orders['latency_sec'].std()
        bot_rate = (driver_orders['latency_sec'] < 2).mean()

        return {
            'acceptance_latency_mean': round(float(latency_mean), 2),
            'acceptance_latency_std': round(float(latency_std), 2),
            'acceptance_bot_rate': round(float(bot_rate), 4)
        }

    def work_hour_distribution(self, orders_df: pd.DataFrame, driver_id: str) -> dict:
        """
        Calculates distribution of active hours.
        Abnormal patterns (e.g., working 22+ hours/day) indicate automation.
        """
        driver_orders = orders_df[
            orders_df['driver_id'] == driver_id
        ].copy()

        if len(driver_orders) < 5:
            return {'daily_active_hours_avg': np.nan, 'max_consecutive_hours': np.nan}

        driver_orders['date'] = pd.to_datetime(driver_orders['order_placed_at']).dt.date
        driver_orders['hour'] = pd.to_datetime(driver_orders['order_placed_at']).dt.hour

        daily_hours = driver_orders.groupby('date')['hour'].nunique()
        max_consecutive = daily_hours.max()
        avg_daily = daily_hours.mean()

        return {
            'daily_active_hours_avg': round(float(avg_daily), 2),
            'max_consecutive_hours': int(max_consecutive) if not pd.isna(max_consecutive) else None
        }

    # =========================================================
    # CATEGORY 3: FINANCIAL & INCENTIVE FEATURES
    # =========================================================

    def reward_dependency_score(self, orders_df: pd.DataFrame,
                                 incentives_df: pd.DataFrame,
                                 driver_id: str) -> float:
        """
        Measures what proportion of a driver's income comes from
        bonuses vs actual delivery earnings.
        High dependency (>40%) flags bonus farming behavior.
        """
        driver_orders = orders_df[orders_df['driver_id'] == driver_id]
        driver_incentives = incentives_df[
            (incentives_df['driver_id'] == driver_id) &
            (incentives_df['status'] == 'paid')
        ]

        delivery_earnings = driver_orders['total_amount'].sum() * 0.80  # Approx driver share
        bonus_earnings = driver_incentives['amount'].sum()
        total_earnings = delivery_earnings + bonus_earnings

        if total_earnings == 0:
            return np.nan

        return round(float(bonus_earnings / total_earnings), 4)

    def incentive_surge_correlation(self, orders_df: pd.DataFrame,
                                     incentives_df: pd.DataFrame,
                                     driver_id: str) -> float:
        """
        Computes Pearson correlation between driver activity spikes
        and active bonus/incentive windows.
        High correlation = driver only works during bonuses (farming indicator).
        """
        driver_orders = orders_df[orders_df['driver_id'] == driver_id].copy()
        driver_orders['date'] = pd.to_datetime(driver_orders['order_placed_at']).dt.date
        daily_orders = driver_orders.groupby('date').size().reset_index(name='order_count')

        driver_incentives = incentives_df[incentives_df['driver_id'] == driver_id].copy()
        driver_incentives['date'] = pd.to_datetime(driver_incentives['created_at']).dt.date
        daily_incentive = driver_incentives.groupby('date').size().reset_index(name='incentive_count')

        merged = daily_orders.merge(daily_incentive, on='date', how='left').fillna(0)

        if len(merged) < 7:
            return np.nan

        corr, _ = stats.pearsonr(merged['order_count'], merged['incentive_count'])
        return round(float(corr), 4)

    # =========================================================
    # CATEGORY 4: DEVICE & IDENTITY FEATURES
    # =========================================================

    def device_stability_score(self, login_df: pd.DataFrame, driver_id: str) -> float:
        """
        Measures how many distinct devices a driver uses.
        High churn in devices = suspicious.
        Returns score 0-1, where 1 = always uses same device.
        """
        driver_logins = login_df[
            (login_df['entity_id'] == driver_id) &
            (login_df['entity_type'] == 'driver')
        ]

        if len(driver_logins) == 0:
            return np.nan

        distinct_devices = driver_logins['device_id'].nunique()
        total_logins = len(driver_logins)

        # Normalize: 1 device for all logins = 1.0 score
        stability = 1.0 - min((distinct_devices - 1) / max(total_logins, 1), 1.0)
        return round(float(stability), 4)

    def login_diversity_score(self, login_df: pd.DataFrame, driver_id: str) -> dict:
        """
        Analyzes diversity of login IPs, locations, and times.
        Returns dict with IP diversity, geo diversity, and VPN usage rate.
        """
        driver_logins = login_df[
            (login_df['entity_id'] == driver_id) &
            (login_df['entity_type'] == 'driver')
        ]

        if len(driver_logins) == 0:
            return {'ip_diversity': np.nan, 'vpn_rate': np.nan}

        return {
            'ip_diversity': int(driver_logins['ip_address'].nunique()),
            'vpn_rate': round(float(driver_logins['is_vpn'].mean()), 4),
            'tor_rate': round(float(driver_logins['is_tor'].mean()), 4),
            'failed_login_rate': round(float((~driver_logins['login_success']).mean()), 4)
        }

    # =========================================================
    # MASTER FEATURE VECTOR BUILDER
    # =========================================================

    def build_driver_feature_vector(self,
                                     driver_id: str,
                                     gps_df: pd.DataFrame,
                                     orders_df: pd.DataFrame,
                                     login_df: pd.DataFrame,
                                     incentives_df: pd.DataFrame) -> dict:
        """
        Builds complete feature vector for a single driver.
        Aggregates all feature categories into one flat dict
        suitable for the Feature Store or ML model input.
        """
        features = {'driver_id': driver_id}

        # GPS / Route features
        features['route_entropy'] = self.route_entropy(gps_df, driver_id)
        features['gps_consistency'] = self.gps_consistency_score(gps_df, driver_id)
        features['delivery_spread'] = self.delivery_clustering_score(orders_df, driver_id)

        # Temporal features
        acceptance_stats = self.acceptance_latency_stats(orders_df, driver_id)
        features.update(acceptance_stats)

        work_stats = self.work_hour_distribution(orders_df, driver_id)
        features.update(work_stats)

        # Financial features
        features['reward_dependency'] = self.reward_dependency_score(
            orders_df, incentives_df, driver_id
        )
        features['incentive_surge_corr'] = self.incentive_surge_correlation(
            orders_df, incentives_df, driver_id
        )

        # Device features
        features['device_stability'] = self.device_stability_score(login_df, driver_id)
        login_diversity = self.login_diversity_score(login_df, driver_id)
        features.update(login_diversity)

        features['computed_at'] = datetime.utcnow().isoformat()
        return features

    def build_feature_store(
        self,
        driver_ids: list,
        gps_df: pd.DataFrame,
        orders_df: pd.DataFrame,
        login_df: pd.DataFrame,
        incentives_df: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Builds Feature Store for all drivers in batch.
        Returns DataFrame ready for ML model input or dashboard.
        """
        feature_vectors = []
        for driver_id in driver_ids:
            fv = self.build_driver_feature_vector(
                driver_id, gps_df, orders_df, login_df, incentives_df
            )
            feature_vectors.append(fv)

        return pd.DataFrame(feature_vectors)


if __name__ == '__main__':
    # Example usage with synthetic test data
    print("Project Sentinel — Feature Engineering Pipeline")
    print("Run with actual data loaded from database via psycopg2 or SQLAlchemy")
    print("See 03_Data_Generation/ for synthetic data generators")
