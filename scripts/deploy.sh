#!/bin/bash
# Script for å deployere tjenester med Helm

helm install flowise ./charts/flowise --namespace default
helm install langflow ./charts/langflow --namespace default
helm install chromadb ./charts/chromadb --namespace default
