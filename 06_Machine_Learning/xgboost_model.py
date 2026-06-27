"""
Project Sentinel — XGBoost Fraud Detection Model
Phase 8: Machine Learning

XGBoost classifier with:
- Class imbalance handling (scale_pos_weight)
- Business cost-aware threshold optimization
- SHAP explainability
- Calibrated probability output
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.metrics import (
    classification_report, roc_auc_score,
    precision_recall_curve, average_precision_score,
    confusion_matrix, brier_score_loss
)
from sklearn.calibration import CalibratedClassifierCV
from sklearn.preprocessing import StandardScaler
import warnings
warnings.filterwarnings('ignore')

try:
    import xgboost as xgb
    import shap
except ImportError:
    print("Install: pip install xgboost shap")
    raise


class SentinelXGBoostModel:
    """
    XGBoost fraud detection model with business-cost optimization.

    Key design decisions:
    - scale_pos_weight handles severe class imbalance (~1% fraud rate)
    - Threshold tuned to minimize business cost (FP cost vs FN cost)
    - SHAP values for investigator explainability
    - Calibration ensures probability scores are reliable for case prioritization
    """

    # Business cost parameters (adjust based on actual cost model)
    COST_MATRIX = {
        'false_negative': 420.0,   # Avg fraud loss per missed case ($)
        'false_positive': 38.0,    # Avg cost of wrongful deactivation ($)
        'true_positive': -80.0,    # Recovery value per caught case ($)
        'true_negative': 0.0       # No cost for correct clearance
    }

    def __init__(self, fraud_rate: float = 0.01):
        self.fraud_rate = fraud_rate
        self.scale_pos_weight = (1 - fraud_rate) / fraud_rate
        self.model = None
        self.calibrated_model = None
        self.optimal_threshold = 0.5
        self.scaler = StandardScaler()
        self.feature_names = None
        self.explainer = None

    def build_model(self) -> xgb.XGBClassifier:
        return xgb.XGBClassifier(
            n_estimators=500,
            max_depth=6,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            min_child_weight=5,
            gamma=0.1,
            reg_alpha=0.1,
            reg_lambda=1.0,
            scale_pos_weight=self.scale_pos_weight,
            use_label_encoder=False,
            eval_metric='aucpr',
            early_stopping_rounds=30,
            random_state=42,
            n_jobs=-1
        )

    def fit(self, X: pd.DataFrame, y: pd.Series,
            eval_size: float = 0.15) -> 'SentinelXGBoostModel':
        """
        Train model with early stopping and probability calibration.
        """
        self.feature_names = list(X.columns)

        X_train, X_eval, y_train, y_eval = train_test_split(
            X, y, test_size=eval_size, stratify=y, random_state=42
        )

        self.model = self.build_model()
        self.model.fit(
            X_train, y_train,
            eval_set=[(X_eval, y_eval)],
            verbose=False
        )

        # Calibrate probabilities using isotonic regression
        base_model = self.build_model()
        self.calibrated_model = CalibratedClassifierCV(
            base_model, method='isotonic', cv=3
        )
        self.calibrated_model.fit(X_train, y_train)

        # Set optimal threshold based on business cost
        val_probs = self.calibrated_model.predict_proba(X_eval)[:, 1]
        self.optimal_threshold = self._find_optimal_threshold(val_probs, y_eval)

        # Build SHAP explainer
        self.explainer = shap.TreeExplainer(self.model)

        print(f"Model trained | Optimal threshold: {self.optimal_threshold:.3f}")
        print(f"  (FP cost: ${self.COST_MATRIX['false_positive']}, "
              f"FN cost: ${self.COST_MATRIX['false_negative']})")
        return self

    def _find_optimal_threshold(self, y_prob: np.ndarray,
                                  y_true: pd.Series) -> float:
        """
        Find threshold that minimizes total business cost.
        """
        thresholds = np.linspace(0.05, 0.95, 100)
        min_cost = np.inf
        optimal_t = 0.5

        for t in thresholds:
            y_pred = (y_prob >= t).astype(int)
            tn, fp, fn, tp = confusion_matrix(y_true, y_pred, labels=[0, 1]).ravel()

            cost = (
                fp * self.COST_MATRIX['false_positive'] +
                fn * self.COST_MATRIX['false_negative'] +
                tp * self.COST_MATRIX['true_positive']
            )

            if cost < min_cost:
                min_cost = cost
                optimal_t = t

        return round(float(optimal_t), 3)

    def predict(self, X: pd.DataFrame) -> np.ndarray:
        probs = self.predict_proba(X)
        return (probs >= self.optimal_threshold).astype(int)

    def predict_proba(self, X: pd.DataFrame) -> np.ndarray:
        return self.calibrated_model.predict_proba(X)[:, 1]

    def evaluate(self, X_test: pd.DataFrame, y_test: pd.Series) -> dict:
        """
        Comprehensive model evaluation with business metrics.
        """
        y_prob = self.predict_proba(X_test)
        y_pred = self.predict(X_test)

        tn, fp, fn, tp = confusion_matrix(y_test, y_pred).ravel()

        # Business cost calculation
        business_cost = (
            fp * self.COST_MATRIX['false_positive'] +
            fn * self.COST_MATRIX['false_negative'] +
            tp * self.COST_MATRIX['true_positive']
        )

        # Baseline cost (flag nothing)
        baseline_cost = y_test.sum() * self.COST_MATRIX['false_negative']

        results = {
            'roc_auc': round(roc_auc_score(y_test, y_prob), 4),
            'pr_auc': round(average_precision_score(y_test, y_prob), 4),
            'precision': round(tp / (tp + fp + 1e-9), 4),
            'recall': round(tp / (tp + fn + 1e-9), 4),
            'false_positive_rate': round(fp / (fp + tn + 1e-9), 4),
            'brier_score': round(brier_score_loss(y_test, y_prob), 4),
            'total_business_cost': round(business_cost, 0),
            'baseline_business_cost': round(baseline_cost, 0),
            'cost_savings_vs_baseline': round(baseline_cost - business_cost, 0),
            'true_positives': int(tp),
            'false_positives': int(fp),
            'false_negatives': int(fn),
            'true_negatives': int(tn),
            'threshold_used': self.optimal_threshold
        }

        return results

    def explain_case(self, X_case: pd.DataFrame,
                     case_id: str = 'UNKNOWN') -> dict:
        """
        Generate SHAP explanation for a specific investigation case.
        Returns dict with risk score and top contributing features.
        Suitable for attachment to investigation case files.
        """
        shap_values = self.explainer.shap_values(X_case)
        risk_score = float(self.predict_proba(X_case)[0])
        prediction = 'FRAUD' if risk_score >= self.optimal_threshold else 'LEGITIMATE'

        # Top features driving the score
        feature_impacts = pd.Series(
            dict(zip(self.feature_names, shap_values[0]))
        ).sort_values(key=abs, ascending=False)

        return {
            'case_id': case_id,
            'risk_score': round(risk_score, 4),
            'prediction': prediction,
            'threshold': self.optimal_threshold,
            'top_5_features': feature_impacts.head(5).round(4).to_dict(),
            'model': 'XGBoost (calibrated)',
            'explained_at': pd.Timestamp.utcnow().isoformat()
        }


if __name__ == '__main__':
    print("Project Sentinel — XGBoost Fraud Detection Model")
    print("Usage:")
    print("  from 06_Machine_Learning.xgboost_model import SentinelXGBoostModel")
    print("  model = SentinelXGBoostModel(fraud_rate=0.01)")
    print("  model.fit(X_train, y_train)")
    print("  results = model.evaluate(X_test, y_test)")
    print("  explanation = model.explain_case(X_case, case_id='CASE-001')")
