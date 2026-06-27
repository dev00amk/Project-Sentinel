"""
Project Sentinel — Fraud Graph Construction
Phase 9: Graph Analytics

Builds a multi-entity fraud graph where:
- Nodes: drivers, devices, IPs, bank accounts, addresses, customers
- Edges: shared_device, logged_in_from, paid_by, lives_at, referred

Uses NetworkX for analysis; graph can be exported to Neo4j or
Gephi for visualization.
"""

import pandas as pd
import numpy as np
from collections import defaultdict

try:
    import networkx as nx
except ImportError:
    print("Install: pip install networkx")
    raise


class FraudGraphBuilder:
    """
    Constructs and analyzes the fraud entity graph.

    Node types and their fraud signal weight:
    - DRIVER:  base node (investigation target)
    - DEVICE:  high weight if emulator/rooted
    - IP:      high weight if VPN/TOR
    - BANK:    medium weight if prepaid/shared
    - ADDRESS: low weight (legitimate sharing possible)
    - CUSTOMER: context for driver-customer collusion
    """

    NODE_TYPE_WEIGHT = {
        'driver': 1.0,
        'device': 2.0,
        'ip': 1.5,
        'bank': 1.8,
        'address': 0.8,
        'customer': 1.0
    }

    def __init__(self):
        self.G = nx.Graph()
        self.node_count = defaultdict(int)

    def add_driver_node(self, driver_id: str, attrs: dict):
        node_id = f"driver_{driver_id}"
        self.G.add_node(node_id, node_type='driver',
                        risk_score=attrs.get('risk_score', 0),
                        status=attrs.get('status', 'active'),
                        **{k: v for k, v in attrs.items()
                           if k not in ('risk_score', 'status')})
        self.node_count['driver'] += 1
        return node_id

    def add_device_node(self, device_id: str, attrs: dict):
        node_id = f"device_{device_id}"
        risk = (
            attrs.get('risk_score', 0) +
            (30 if attrs.get('is_emulator') else 0) +
            (25 if attrs.get('is_rooted') else 0) +
            (20 if attrs.get('is_vpn_detected') else 0)
        )
        self.G.add_node(node_id, node_type='device',
                        risk_score=min(risk, 100),
                        **attrs)
        self.node_count['device'] += 1
        return node_id

    def add_edge(self, node1: str, node2: str, edge_type: str,
                 weight: float = 1.0, attrs: dict = None):
        self.G.add_edge(node1, node2,
                        edge_type=edge_type,
                        weight=weight,
                        **(attrs or {}))

    def build_from_dataframes(
        self,
        drivers_df: pd.DataFrame,
        devices_df: pd.DataFrame,
        login_df: pd.DataFrame,
        payments_df: pd.DataFrame,
        referrals_df: pd.DataFrame
    ):
        """
        Constructs the full fraud graph from database DataFrames.
        """
        print(f"Building fraud graph...")

        # Add driver nodes
        for _, row in drivers_df.iterrows():
            self.add_driver_node(row['driver_id'], row.to_dict())

        # Add device nodes and edges
        device_nodes = {}
        for _, row in devices_df.iterrows():
            node_id = self.add_device_node(row['device_id'], row.to_dict())
            device_nodes[row['device_id']] = node_id

        # Driver <-> Device edges from login events
        driver_device_pairs = login_df[
            login_df['entity_type'] == 'driver'
        ][['entity_id', 'device_id']].drop_duplicates()

        for _, row in driver_device_pairs.iterrows():
            driver_node = f"driver_{row['entity_id']}"
            device_node = f"device_{row['device_id']}"
            if self.G.has_node(driver_node) and self.G.has_node(device_node):
                self.add_edge(driver_node, device_node,
                              edge_type='logged_in_from', weight=1.0)

        # Driver <-> Driver edges from referrals
        for _, row in referrals_df[
            referrals_df['referrer_type'] == 'driver'
        ].iterrows():
            node1 = f"driver_{row['referrer_id']}"
            node2 = f"driver_{row['referred_id']}"
            if self.G.has_node(node1) and self.G.has_node(node2):
                self.add_edge(node1, node2,
                              edge_type='referred',
                              weight=1.5 if row.get('is_fraudulent') else 0.5)

        print(f"Graph built: {self.G.number_of_nodes()} nodes, "
              f"{self.G.number_of_edges()} edges")
        return self

    # =========================================================
    # GRAPH ANALYTICS
    # =========================================================

    def get_connected_components(self, min_size: int = 3) -> list:
        """
        Returns connected components of size >= min_size.
        Large components indicate fraud rings.
        """
        components = list(nx.connected_components(self.G))
        large_components = [
            sorted(c) for c in components if len(c) >= min_size
        ]
        return sorted(large_components, key=len, reverse=True)

    def compute_pagerank(self, alpha: float = 0.85) -> pd.DataFrame:
        """
        PageRank identifies central nodes in fraud networks.
        High PageRank = hub connecting many other accounts (fraud ring coordinator).
        """
        pr = nx.pagerank(self.G, alpha=alpha, weight='weight')
        df = pd.DataFrame([
            {'node_id': k, 'pagerank': v,
             'node_type': self.G.nodes[k].get('node_type', 'unknown')}
            for k, v in pr.items()
        ]).sort_values('pagerank', ascending=False)
        return df

    def compute_betweenness(self, top_n: int = 100) -> pd.DataFrame:
        """
        Betweenness centrality identifies nodes that act as bridges
        between sub-networks (money mules, coordinators).
        """
        bc = nx.betweenness_centrality(self.G, weight='weight', normalized=True)
        df = pd.DataFrame([
            {'node_id': k, 'betweenness': v,
             'node_type': self.G.nodes[k].get('node_type', 'unknown')}
            for k, v in bc.items()
        ]).sort_values('betweenness', ascending=False).head(top_n)
        return df

    def detect_fraud_communities(self) -> dict:
        """
        Louvain community detection to identify fraud clusters.
        Returns dict mapping community_id -> list of node_ids.
        """
        try:
            from networkx.algorithms.community import louvain_communities
            communities = louvain_communities(self.G, weight='weight', seed=42)
        except ImportError:
            # Fallback to greedy modularity
            from networkx.algorithms.community import greedy_modularity_communities
            communities = list(greedy_modularity_communities(self.G))

        community_map = {}
        for idx, community in enumerate(communities):
            community_map[idx] = {
                'nodes': list(community),
                'size': len(community),
                'driver_count': sum(1 for n in community
                                    if self.G.nodes[n].get('node_type') == 'driver'),
                'avg_risk': np.mean([
                    self.G.nodes[n].get('risk_score', 0) for n in community
                ])
            }

        return dict(sorted(community_map.items(),
                           key=lambda x: x[1]['size'], reverse=True))

    def export_fraud_subgraph(self, driver_id: str,
                               depth: int = 2) -> nx.Graph:
        """
        Exports the ego network for a specific driver investigation.
        Returns subgraph of all nodes within 'depth' hops.
        Suitable for Gephi visualization or Neo4j import.
        """
        center_node = f"driver_{driver_id}"
        if not self.G.has_node(center_node):
            raise ValueError(f"Driver {driver_id} not found in graph")

        ego_nodes = nx.ego_graph(self.G, center_node, radius=depth).nodes()
        return self.G.subgraph(ego_nodes).copy()

    def get_ring_summary(self) -> pd.DataFrame:
        """
        Summarizes all detected fraud rings (connected components
        with multiple driver nodes).
        """
        components = self.get_connected_components(min_size=3)
        rings = []

        for comp in components:
            driver_nodes = [n for n in comp
                            if self.G.nodes[n].get('node_type') == 'driver']
            device_nodes = [n for n in comp
                            if self.G.nodes[n].get('node_type') == 'device']

            if len(driver_nodes) >= 2:
                avg_risk = np.mean([
                    self.G.nodes[n].get('risk_score', 0) for n in driver_nodes
                ])
                rings.append({
                    'ring_size': len(comp),
                    'driver_count': len(driver_nodes),
                    'device_count': len(device_nodes),
                    'avg_driver_risk_score': round(avg_risk, 2),
                    'driver_nodes': driver_nodes
                })

        return pd.DataFrame(rings).sort_values('driver_count', ascending=False)


if __name__ == '__main__':
    print("Project Sentinel — Fraud Graph Analytics")
    print("Usage:")
    print("  from 08_Graph_Analytics.build_graph import FraudGraphBuilder")
    print("  builder = FraudGraphBuilder()")
    print("  builder.build_from_dataframes(drivers_df, devices_df, login_df, ...)")
    print("  rings = builder.get_ring_summary()")
    print("  communities = builder.detect_fraud_communities()")
