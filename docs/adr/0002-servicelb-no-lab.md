# ADR 0002 — ServiceLB como LoadBalancer no lab

- **Status:** aceito
- **Data:** 2026-11-17

## Contexto

No Proxmox não existe provedor de nuvem. Um Service `type: LoadBalancer`, como o do Traefik, fica com `EXTERNAL-IP <pending>` se nada no cluster atendê-lo. Na AWS, quem faz esse papel é o AWS Load Balancer Controller, criando um NLB.

## Decisão

Usar o **ServiceLB** (klipper-lb), que já vem habilitado no k3s.

- O Service recebe os IPs dos próprios nós (`192.168.1.200–.202`) como `EXTERNAL-IP`.
- Não é preciso reservar uma faixa extra de IPs fora do DHCP.

## Alternativa considerada

**MetalLB:** dá a cada Service um IP próprio, tirado de um pool anunciado via ARP. Exige instalar mais um componente e reservar uma faixa de IPs. Não muda nada na demonstração de autoscaling.

## Consequências

- Nada a instalar ou manter.
- Cada porta (80/443) só pode ser usada por um Service `LoadBalancer` no cluster, o que basta, porque só o Traefik é exposto.
- Ainda falta validar na fase 5 que o IP real do cliente chega ao Traefik com `externalTrafficPolicy: Local`. Se não chegar, o MetalLB vira o plano B.
