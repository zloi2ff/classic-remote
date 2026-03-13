# Philips TV Remote

Веб-пульт для телевізора Philips Smart TV (JointSpace API v1/v5/v6). Доступний як веб-додаток та нативний iOS застосунок з віджетом на домашньому екрані.

![Version](https://img.shields.io/badge/version-1.1-blue)
![Remote](https://img.shields.io/badge/TV-Philips%206158-blue)
![Python](https://img.shields.io/badge/Python-3.x-green)
![Capacitor](https://img.shields.io/badge/Capacitor-8.x-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

[English](README.md) | **Українська**

<p align="center">
  <img src="screenshot-collapsed.png" width="280" alt="Згорнутий">
  <img src="screenshot-expanded.png" width="280" alt="Розгорнутий">
</p>

## Підтримувані телевізори

Додаток використовує JointSpace API (порт 1925) та автоматично визначає версію API. При підключенні перебирає v1 → v6 → v5.

> **Активація JointSpace на телевізорах 2011–2015:** відкрий меню телевізора і введи код `5646877223` на пульті.

### API v1 — HTTP, без авторизації (2009–2015)

Всі не-Android телевізори Philips з 2009 до 2015 року. Підключення без паринга.

| Рік | Шаблон моделі | Приклад |
|-----|--------------|---------|
| 2009 | xxPFL8xxx, xxPFL9xxx | 42PFL8684H/12 |
| 2010 | xxPFL7xxx, xxPFL8xxx, xxPFL9xxx | 46PFL8605H/12 |
| 2011 | xxPFL5**6**xx–xxPFL9**6**xx | 42PFL6158K/12 |
| 2012 | xxPFL5**7**xx–xxPFL8**7**xx | 47PFL6678S/12 |
| 2013 | xxPFL5**8**xx–xxPFL8**8**xx _(не Android)_ | 55PFL6678S/12 |
| 2014 | xxPFL5**9**xx, xxPUS6**9**xx _(не Android)_ | 42PUS6809/12 |
| 2015 | xxPFL5**0**xx, xxPUS6**0**xx _(не Android)_ | 43PUS6031/12 |

Остання цифра 4-значного номера серії кодує рік (6=2011, 7=2012, 8=2013, 9=2014, 0=2015).

### API v5 — HTTP, без авторизації (2014–2015)

Перехідне покоління. Той самий протокол що й v1, але розширений набір команд. Багато v5 телевізорів також відповідають на `/1/`.

| Рік | Шаблон моделі |
|-----|--------------|
| 2014–2015 | xxPUS6**9**xx, xxPUS7**9**xx, xxPUS6**0**xx, xxPUS7**0**xx _(не Android / Saphi OS)_ |

### API v6 — HTTPS, потрібен PIN-паринг (2016–дотепер)

#### Saphi OS (не Android) — порт 1925, HTTPS

Бюджетні та середні телевізори з 2016+ на власній ОС Philips Saphi.

| Рік | Шаблон моделі | Приклад |
|-----|--------------|---------|
| 2016 | xxPUS6**1**xx, xxPFT5**1**xx | 43PUS6162/12 |
| 2017 | xxPUS6**2**xx | 65PUS6162/12 |
| 2018 | xxPUS6**3**xx | 43PUS6753/12 |
| 2019+ | xxPUS6**4**xx та нижчі PUS7xxx | — |

#### Android TV — порт 1926, HTTPS

Середні та топові телевізори з 2016+ на Android TV. Базові команди (гучність, standby, навігація) працюють. Повний контроль потребує порт 1926 + digest auth.

| Рік | Шаблон моделі | Приклад |
|-----|--------------|---------|
| 2016 | xxPUS7**1**xx, xxPUS8**1**xx | 49PUS7101/12 |
| 2017 | xxPUS7**2**xx, OLEDxx**2** | 55PUS7502/12 |
| 2018 | xxPUS7**3**xx, xxPUS8**3**xx | 58PUS7304/12 |
| 2019 | xxPUS7**4**xx, OLEDxx**4** | 55OLED804/12 |
| 2020+ | xxPUS7**5**xx та новіші | — |

> Всі OLED моделі (OLED803, OLED804 тощо) — це Android TV з API v6 на порту 1926.

## Можливості

- Автопошук телевізорів Philips у локальній мережі
- Ручне введення IP-адреси телевізора
- Увімкнення/вимкнення
- Навігація (стрілки, OK, Назад, Додому)
- Керування гучністю (+/-, без звуку, слайдер)
- Перемикання каналів (+/-)
- Кольорові кнопки (червона, зелена, жовта, синя)
- Керування відтворенням (play, pause, stop, перемотка)
- Швидке перемикання джерел (TV, HDMI, Blu-ray тощо)
- Візуальний відгук з вібрацією (iOS)
- PWA підтримка (додавання на домашній екран iOS/Android)
- Нативний iOS застосунок (Capacitor)
- **Віджет на домашньому екрані** — Vol+/Vol-/Mute/Standby без відкриття додатку (iOS 17+, Liquid Glass на iOS 26+)

## Встановлення

### Швидкий старт

```bash
git clone https://github.com/zloi2ff/philips-remote.git
cd philips-remote
python3 server.py
```

Відкрий http://localhost:8888 у браузері. Додаток запропонує знайти телевізор у мережі або ввести IP вручну.

### Налаштування

Сервер налаштовується через змінні середовища:

```bash
# Встановити IP телевізора (опціонально — можна налаштувати через веб-інтерфейс)
TV_IP=192.168.1.100 python3 server.py

# Змінити порт сервера
SERVER_PORT=9000 python3 server.py

# Порт телевізора (за замовчуванням: 1925)
TV_PORT=1925 python3 server.py
```

## Використання на iPhone/Android

### Веб-додаток (PWA)

1. Відкрий `http://IP_СЕРВЕРА:8888` в Safari/Chrome
2. Натисни Поділитись → "На Початковий екран"
3. Використовуй як звичайний додаток

### Нативний iOS застосунок

Збірка та встановлення через Xcode:

```bash
# Встановити залежності
npm install

# Синхронізувати з iOS
npx cap sync ios

# Відкрити в Xcode
npx cap open ios
```

В Xcode:
1. Вибери свій iPhone
2. Налаштуй підпис (Signing & Capabilities → Team)
3. Натисни Run (Cmd+R)

## API

Телевізор використовує JointSpace API v1:

| Endpoint | Метод | Опис |
|----------|-------|------|
| `/1/system` | GET | Інформація про систему |
| `/1/audio/volume` | GET/POST | Керування гучністю |
| `/1/sources` | GET | Доступні джерела |
| `/1/sources/current` | POST | Перемикання джерела |
| `/1/input/key` | POST | Надсилання команди |

### Ендпоінти сервера

| Endpoint | Метод | Опис |
|----------|-------|------|
| `/discover` | GET | Пошук телевізорів Philips у мережі |
| `/config` | GET | Поточна конфігурація TV IP |
| `/config` | POST | Встановити IP TV (`{"ip": "...", "port": ...}`) |

### Коди клавіш

`Standby`, `VolumeUp`, `VolumeDown`, `Mute`, `ChannelStepUp`, `ChannelStepDown`, `CursorUp`, `CursorDown`, `CursorLeft`, `CursorRight`, `Confirm`, `Back`, `Home`, `Source`, `Info`, `Options`, `Find`, `Adjust`, `Digit0`-`Digit9`, `Play`, `Pause`, `Stop`, `Rewind`, `FastForward`, `Record`, `RedColour`, `GreenColour`, `YellowColour`, `BlueColour`

## Ліцензія

MIT
