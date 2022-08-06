#!/usr/bin/env python
# coding=utf-8

from kubernetes import client, config
from kubernetes.client import Configuration
import urllib3

class K8sClient:
    def __init__(self):
        # 参考 https://github.com/kubernetes-client/python/blob/master/examples/in_cluster_config.py
        # 需要配置 ClusterRole & ClusterRoleBinding & ServiceAccount
        config.load_incluster_config()
        Configuration._default.verify_ssl = False
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        self.k8s_client_v1 = client.CoreV1Api()


    def list_namespaces(self):
        namespaces = []

        response = self.k8s_client_v1.list_namespace(limit=50, timeout_seconds=60, watch=False)
        for i in response.items:
            namespaces.append(i.metadata.name)
        return namespaces


    def exist_configmap(self, namespace, configmap_name):
        response = self.k8s_client_v1.list_namespaced_config_map(namespace=namespace)
        for i in response.items:
            if i.metadata.name == configmap_name:
                return True
        return False


    def get_configmap(self, namespace, configmap_name):
        return self.k8s_client_v1.read_namespaced_config_map(name=configmap_name, namespace=namespace)
