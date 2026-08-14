# PWR — Spec-Driven Development

## 1. Visão do Produto

PWR é um app mobile de acompanhamento de treinos de academia, construído com Flutter, focado em registrar treinos de forma extremamente rápida, minimalista e sem distrações.

A proposta central é substituir o tradicional bloco de notas da academia, permitindo registrar séries, cargas, repetições e descanso em poucos toques.

O app será **offline-first**: o treino deve funcionar normalmente sem internet. Os dados são persistidos localmente e sincronizados posteriormente com o backend.

---

## 2. Objetivos

### Objetivos principais

- Registrar treinos rapidamente.
- Funcionar completamente offline durante o treino.
- Mostrar histórico e evolução do usuário.
- Permitir criação e gerenciamento de rotinas.
- Oferecer recursos avançados através do PWR PRO.
- Permitir compartilhamento visual de resultados.
- Sincronizar dados entre dispositivos para usuários PRO.

### Fora do escopo inicial

- Rede social/feed.
- Chat.
- IA de treino.
- Marketplace.
- Microservices.
- Redis/Celery.
- Smartwatch no MVP.

---

## 3. Stack

### Mobile

- Flutter
- Dart
- Riverpod — gerenciamento de estado
- GoRouter — navegação
- Drift + SQLite — persistência local
- Dio — HTTP client
- Firebase Auth — autenticação
- connectivity_plus — detecção de conectividade
- Freezed — models/immutability
- RevenueCat — assinaturas e entitlement PRO

### Backend

- FastAPI
- Python
- SQLAlchemy
- Alembic
- PostgreSQL
- Firebase Admin SDK — validação dos tokens do Firebase Auth

### Infraestrutura

- Backend FastAPI em container
- PostgreSQL gerenciado ou VPS
- Firebase apenas para Authentication
- RevenueCat para gerenciamento de assinaturas

---

## 4. Arquitetura

```text
                         PWR Flutter
                              |
              +---------------+---------------+
              |                               |
              v                               v
       Firebase Auth                    Drift / SQLite
              |                         (local-first)
              |                               |
              |                         Sync Queue
              |                               |
              +-------------------------------+
                              |
                         FastAPI API
                              |
                         PostgreSQL
```

### Responsabilidades

**Firebase Auth**
- Cadastro/login.
- Login social futuramente.
- Recuperação de senha.
- Identidade do usuário.
- ID token.

**Flutter + SQLite**
- Fonte de verdade para a experiência local.
- Rotinas.
- Exercícios.
- Treinos.
- Séries.
- Histórico.
- PRs.
- Estado de treino em andamento.
- Fila de sincronização.

**FastAPI + PostgreSQL**
- Persistência cloud.
- Sincronização.
- Dados da conta.
- Dados remotos.
- Analytics.
- Exportações e futuras regras de negócio.

**RevenueCat**
- Produtos e planos.
- Assinaturas App Store / Google Play.
- Entitlement `pro`.
- Estado da assinatura.
- Restore Purchases.

---

## 5. Princípio Offline-First

Toda ação crítica do treino deve funcionar sem internet.

Fluxo:

```text
Usuário registra série
        ↓
SQLite
        ↓
UI atualiza imediatamente
        ↓
Sync Queue
        ↓
Internet disponível?
   ┌────┴────┐
   │         │
  SIM       NÃO
   │         │
   ↓         ↓
FastAPI   pending
   │
   ↓
PostgreSQL
```

O usuário não deve precisar esperar uma resposta da API para concluir uma série.

### IDs

Todos os registros devem receber UUID no dispositivo.

Isso permite:

- criação offline;
- sincronização posterior;
- idempotência;
- sincronização entre dispositivos.

---

## 6. Modelo de Dados Local

Entidades principais:

- User
- Exercise
- Routine
- RoutineExercise
- WorkoutSession
- WorkoutExercise
- WorkoutSet
- PersonalRecord
- BodyMeasurement
- SyncOperation

### WorkoutSet

```text
id
workout_exercise_id
set_number
type
weight
reps
rir
completed
completed_at
created_at
updated_at
deleted_at
version
```

`type`:

- warmup
- normal
- failure
- drop_set

### SyncOperation

```text
id
entity_type
entity_id
operation
payload
created_at
attempts
last_error
synced_at
```

Operações:

- upsert
- delete

---

## 7. Backend API

Base:

```text
/api/v1
```

### Auth / User

```text
GET /users/me
POST /users/bootstrap
```

O FastAPI valida o Firebase ID Token através do Firebase Admin SDK.

### Exercises

```text
GET /exercises
POST /exercises
PATCH /exercises/{id}
DELETE /exercises/{id}
```

### Routines

```text
GET /routines
POST /routines
PATCH /routines/{id}
DELETE /routines/{id}
```

### Workouts

```text
GET /workouts
GET /workouts/{id}
POST /workouts
PATCH /workouts/{id}
```

### Sync

```text
POST /sync/push
POST /sync/pull
```

O sync deve ser idempotente.

### Analytics

```text
GET /analytics/exercises/{id}
GET /analytics/muscles
GET /analytics/overview
```

Analytics avançados podem ser inicialmente calculados no cliente quando isso for suficiente.

---

## 8. Sincronização

### Push

O app envia operações pendentes:

```json
{
  "operations": [
    {
      "id": "operation-uuid",
      "entity": "workout_set",
      "entity_id": "set-uuid",
      "operation": "upsert",
      "version": 1,
      "data": {}
    }
  ]
}
```

### Pull

O app solicita alterações posteriores ao seu cursor:

```json
{
  "cursor": "last-known-cursor"
}
```

O backend retorna:

- alterações;
- deleções;
- novo cursor.

### Conflitos

No MVP:

- usar `version` + `updated_at`;
- registros de treino finalizados são tratados como praticamente imutáveis;
- para edições concorrentes simples, a versão mais recente prevalece;
- operações devem ser idempotentes.

Não implementar um sistema de resolução de conflitos complexo no MVP.

---

## 9. Autenticação

Firebase Auth será responsável pela autenticação.

Fluxo:

```text
Flutter
  ↓
Firebase Auth
  ↓
Firebase UID + ID Token
  ↓
FastAPI
  ↓
Firebase Admin SDK
  ↓
PostgreSQL user
```

O usuário pode iniciar o app sem cadastro.

Após o primeiro treino, o app pode incentivar a criação de uma conta para proteger o progresso e habilitar recursos cloud.

Dados locais devem ser associados à conta durante o processo de bootstrap.

---

## 10. Navegação

Bottom navigation:

```text
TREINO
PROGRESSO
   +
CORPO
PERFIL
```

### Telas

- Onboarding
- Home
- Rotinas
- Criar/editar rotina
- Biblioteca de exercícios
- Exercício
- Workout
- Workout Summary
- Histórico
- Detalhes do treino
- Progresso
- Corpo
- Perfil
- Paywall
- Configurações

---

## 11. Fluxo Principal de Treino

```text
Home
 ↓
Selecionar rotina
 ↓
Workout
 ↓
Registrar série
 ↓
Rest Timer
 ↓
Próxima série
 ↓
Finalizar treino
 ↓
Workout Summary
 ↓
PR / progresso
 ↓
Share Card
```

A tela de workout deve priorizar:

- peso;
- repetições;
- série;
- conclusão;
- descanso;
- desempenho anterior.

### Previous Performance

O app deve mostrar a carga/repetições anteriores e, quando apropriado, sugerir os valores na próxima sessão.

---

## 12. Recursos Free

- Registro ilimitado de treinos.
- Biblioteca de exercícios.
- Exercícios personalizados.
- Rest Timer.
- Séries Warm-up, Normal, Failure e Drop Set.
- Supersets.
- Integração básica com Health / Google Fit.
- Exportação CSV.
- Até 3 rotinas personalizadas.

O Free deve ser suficientemente útil para substituir um bloco de notas.

---

## 13. Recursos PRO

- Rotinas ilimitadas.
- Estatísticas avançadas.
- Gráficos de volume.
- Gráficos de 1RM.
- Cálculo de 1RM.
- PRs automáticos.
- Medições corporais avançadas.
- Calculadora de aquecimento.
- Calculadora de anilhas.
- Cloud Sync.
- Integração avançada com smartwatch futuramente.
- Muscle Heatmap.

---

## 14. RevenueCat

RevenueCat será utilizado para abstrair as compras da App Store e Google Play.

### Entitlement

```text
pro
```

### Produto

Exemplo:

```text
pwr_pro_monthly
pwr_pro_yearly
```

Os IDs finais devem ser configurados no RevenueCat e nas respectivas lojas.

### Fluxo

```text
Flutter
   ↓
RevenueCat SDK
   ↓
App Store / Google Play
   ↓
RevenueCat
   ↓
Customer Entitlements
   ↓
pro = active
```

O app deve consultar o entitlement `pro` para liberar funcionalidades.

### Backend

O backend não deve confiar somente no estado enviado pelo Flutter.

RevenueCat deve ser a fonte de verdade da assinatura.

Para recursos server-side, o RevenueCat pode notificar o backend através de webhooks:

```text
RevenueCat
   ↓
POST /webhooks/revenuecat
   ↓
FastAPI
   ↓
PostgreSQL
```

Eventos relevantes:

- initial purchase
- renewal
- cancellation
- expiration
- uncancellation
- billing issue

O backend pode manter um snapshot do entitlement para regras de negócio, mas o RevenueCat continua sendo a autoridade sobre a assinatura.

### Restore

O usuário deve conseguir restaurar compras através do RevenueCat.

---

## 15. Paywall

O paywall deve aparecer contextualmente.

Exemplos:

```text
3/3 rotinas usadas
→ PRO

Histórico antigo
→ PRO

Analytics avançados
→ PRO

Cloud Sync
→ PRO
```

Não transformar o app em uma sequência constante de paywalls.

---

## 16. Share Cards

Share Cards devem ser gerados localmente no Flutter.

Exemplos:

- resumo do treino;
- novo PR;
- volume;
- duração;
- exercícios;
- estatísticas.

Formato visual:

```text
PWR

PUSH A

52 MIN
6,240 KG
24 SETS

NEW PR
BENCH PRESS
85 KG × 6

@username
```

O compartilhamento deve utilizar os mecanismos nativos do sistema.

---

## 17. Design System

Direção visual:

- Dark-first.
- Minimalista.
- Técnico.
- Sem excesso de elementos.
- Roxo como accent.
- Poppins para interface.
- Azeret Mono para números, métricas e labels técnicos.

Cores base aproximadas:

```text
Background: #121212
Surface:    #1C1C1C
Text:       #E6E4E4
Muted:      #9A9A9A
Accent:     #B06AE8
```

Manter consistência com o protótipo existente.

---

## 18. Estrutura Flutter

```text
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
│
├── core/
│   ├── auth/
│   ├── database/
│   ├── network/
│   ├── sync/
│   └── storage/
│
├── features/
│   ├── onboarding/
│   ├── home/
│   ├── routines/
│   ├── exercises/
│   ├── workout/
│   ├── history/
│   ├── progress/
│   ├── body/
│   ├── sharing/
│   ├── subscription/
│   └── profile/
│
└── shared/
    ├── widgets/
    ├── components/
    └── utils/
```

---

## 19. Estrutura FastAPI

```text
app/
├── main.py
├── core/
│   ├── config.py
│   ├── database.py
│   └── firebase.py
│
├── models/
├── schemas/
├── repositories/
├── services/
│   ├── sync_service.py
│   ├── workout_service.py
│   ├── analytics_service.py
│   └── user_service.py
│
├── api/
│   └── v1/
│       ├── users.py
│       ├── exercises.py
│       ├── routines.py
│       ├── workouts.py
│       ├── sync.py
│       ├── analytics.py
│       └── webhooks.py
│
└── migrations/
```

---

## 20. Fases de Desenvolvimento

### Fase 1 — Offline Core

Implementar:

- Design system.
- Onboarding.
- Home.
- SQLite/Drift.
- Exercícios.
- Rotinas.
- Workout.
- Séries.
- Rest Timer.
- Histórico local.
- Workout Summary.

Objetivo: conseguir fazer um treino completo sem internet.

### Fase 2 — Auth

Implementar:

- Firebase Auth.
- Login.
- Cadastro.
- Logout.
- Bootstrap de usuário.
- Associação dos dados locais à conta.

### Fase 3 — Backend + Sync

Implementar:

- FastAPI.
- PostgreSQL.
- Firebase token validation.
- Push sync.
- Pull sync.
- Sync queue.
- Retry.
- Conflict handling.
- Multi-device sync.

### Fase 4 — Monetização

Implementar:

- RevenueCat.
- Produtos mensal/anual.
- Entitlement `pro`.
- Paywall.
- Restore purchases.
- RevenueCat webhooks.
- Estado PRO no backend.

### Fase 5 — PRO

Implementar:

- 1RM.
- PRs.
- Analytics.
- Gráficos.
- Medições.
- Calculadoras.
- Muscle heatmap.
- Cloud Sync.

### Fase 6 — Growth

Posteriormente:

- Health/Google Fit.
- Smartwatch.
- Push notifications.
- Share Cards avançados.
- Novos recursos de análise.

---

## 21. MVP

O primeiro lançamento deve priorizar:

```text
✓ Flutter
✓ Offline-first
✓ SQLite/Drift
✓ Firebase Auth
✓ FastAPI
✓ PostgreSQL
✓ Sync
✓ Exercise library
✓ Custom exercises
✓ 3 routines
✓ Workout execution
✓ Rest Timer
✓ Previous performance
✓ Workout history
✓ CSV
✓ Share Card
✓ RevenueCat
✓ PRO entitlement
```

Não bloquear o lançamento por causa de:

```text
- Smartwatch
- Heatmap avançado
- IA
- Analytics muito sofisticados
- Social features
```

---

## 22. Princípios do Projeto

1. **Offline first.**
2. **O treino nunca deve depender da internet.**
3. **Salvar localmente antes de sincronizar.**
4. **A UI deve responder imediatamente.**
5. **Firebase é somente autenticação.**
6. **FastAPI é o backend principal.**
7. **PostgreSQL é a fonte de verdade cloud.**
8. **RevenueCat é a fonte de verdade para assinaturas.**
9. **Free deve ser genuinamente útil.**
10. **PRO deve vender progresso, analytics e cloud, não apenas limitações.**
11. **Evitar complexidade de infraestrutura antes de existir necessidade.**
12. **O fluxo de registro de uma série é a principal UX do produto.**

---

## 23. Critério de Sucesso do MVP

O PWR estará pronto para validação quando um usuário conseguir:

```text
Abrir o app
    ↓
Escolher uma rotina
    ↓
Iniciar treino
    ↓
Registrar peso/reps
    ↓
Usar rest timer
    ↓
Continuar sem internet
    ↓
Finalizar treino
    ↓
Ver resumo
    ↓
Ver histórico
    ↓
Compartilhar resultado
```

sem depender do backend para nenhuma ação crítica.

Depois, com internet:

```text
SQLite
  ↓
Sync
  ↓
FastAPI
  ↓
PostgreSQL
```

e o mesmo usuário poderá recuperar seus dados em outro dispositivo.

---

## 24. Resultado Esperado

O resultado final deve ser um app:

**rápido, minimalista, offline-first e focado em progresso**, com uma arquitetura simples o suficiente para um MVP, mas preparada para evoluir para sincronização multi-device, assinatura PRO, analytics e integrações futuras.
