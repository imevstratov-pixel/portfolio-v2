---
seo:
  title: 'Кейсы: консультации, AI-конвейер и курсы — Даниил Евстратов'
  description: 'Кейсы из штата и заказы: модель компетенций, AI-конвейер производства курсов, разбор и пересборка курсов, ИИ-боты и тренажёры. В каждом кейсе задача, что я сделал и результат.'
blocks:
- id: intro
  type: intro
  heading: Кейсы
  lead: Работа в штате и на заказ. В каждом кейсе задача, что я сделал, результат и что из этого сделаю для вас.
- id: toc
  type: cases-toc
  heading: Оглавление по услугам
  groups:
  - service: consulting
  - service: pipeline
  - service: audit
  - service: course
  - service: app
    products:
    - barba
    - wishlist
  - service: game
    products:
    - skrizhal
    - top-pick
    - dobei
  - service: guide
  row:
    fields:
    - shortTitle
    - industry
    - duration
  productRow:
    labels:
    - Свой продукт
    - Разработка
    hrefPattern: /products/#{anchor}
  legend:
    origin: 'Происхождение: В штате, На заказ, Для близкого человека, Свой продукт.'
    direction: 'Направление: Обучение, Разработка, Мост — методика и код в одних руках.'
- id: cases
  type: cases-list
  sort: order
  sections:
  - Контекст
  - Что сделал
  - Результат
  - Что из этого сделаю для вас
  labels:
  - origin
  - industry
  - year
  - duration
  - direction
  statusField: status
  serviceLinkLabel: Что из этого сделаю для вас
- id: contact
  type: contact
  anchor: contact
  heading: Обсудим, что я могу сделать для вашего курса или команды?
  hint: global.telegram.gridHint
  buttons:
  - Консультация
  - Конвейер
  - Аудит
  - Курс
  - Приложение
  - Игра
  - Гайд
  - Другое
  email: global.email.line
  lines:
  - global.work.price
  - global.work.payment
  - global.work.languages
  workload: global.work.howWeStart.workload
---


