# ADR 0001 — Traefik como gateway

- **Status:** aceito
- **Data:** 2026-11-17

## Contexto

O projeto precisa de um gateway na frente da API que faça roteamento, rate limit por IP de origem e exponha métricas Prometheus para escalar por RPS. O plano inicial usava o Envoy Gateway (Gateway API).

## Decisão

Usar o **Traefik** como gateway, nos dois ambientes.

- Instalado pelo chart Helm oficial, com versão fixada, via Argo CD.
- O Traefik embutido do k3s fica desabilitado (`--disable=traefik`), para dev e prod terem a mesma versão e configuração, e para tudo passar pelo Git.
- Versão do Traefik ≥ 3.4.
- Roteamento com `IngressRoute` e rate limit com o middleware `rateLimit` (`sourceCriterion.ipStrategy`) usando o bloco `redis`, que conta globalmente entre réplicas.

## Consequências

- Menos peças que o Envoy Gateway: não há controller separado nem rate limit service. Continua sendo preciso um Redis só para o rate limit, separado do Redis da app.
- Sem o bloco `redis`, o `rateLimit` contaria em memória, por réplica, e o limite efetivo por IP subiria conforme o KEDA escalasse o Traefik. Com o Redis, o limite fica global.
- O middleware `distributedRateLimit` que aparece na documentação é exclusivo do Traefik Hub (pago) e não é usado.
- O rate limit por IP depende de o IP real do cliente chegar ao Traefik (`externalTrafficPolicy: Local`). Ver ADR 0002.
