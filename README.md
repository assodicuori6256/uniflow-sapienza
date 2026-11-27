# 🎓 UniFlow — Il tuo ecosistema universitario (Sapienza Farmacia)

> **Un'applicazione moderna e nativa multi-piattaforma per macOS, iOS (iPhone) e iPadOS (iPad)** progettata su misura per gli studenti della facoltà di **Farmacia della Sapienza Università di Roma**: lezioni tra gli edifici CU019, CU014 e CU026, piano di studi da 300 CFU, docenti personalizzabili, appunti con modelli di laboratorio galenico e schede farmaco, trasporti romani (Metro B Policlinico, Tram 3/19, Bus Atac) e sessioni di studio con pause rigeneranti e motivazioni personalizzate.

---

## 👨‍💻 Sviluppatore & Contatti Ufficiali

- **Autore & Sviluppatore**: Aldo Cuko
- **Email di Contatto**: [aldo.superiori@gmail.com](mailto:aldo.superiori@gmail.com)
- **Repository Ufficiale GitHub**: [https://github.com/assodicuori6256/uniflow-sapienza](https://github.com/assodicuori6256/uniflow-sapienza)
- **Licenza & Privacy**: 100% Offline-First. Nessun dato lascia il tuo dispositivo.

---

## 📱 Supporto Multi-Piattaforma Universale

UniFlow è sviluppato con architettura adattiva in **SwiftUI**:

1. **💻 Mac (MacBook Air/Pro M1, M2, M3 & Intel)**:
   - Layout desktop a colonna multipla con barra laterale rapida (`NavigationSplitView`).
   - Scorciatoie da tastiera native (<kbd>⌘</kbd> + <kbd>1</kbd>..<kbd>7</kbd>, <kbd>⌘</kbd> + <kbd>N</kbd>, <kbd>⌘</kbd> + <kbd>T</kbd>).
   - App Sandbox Apple abilitata e conformità App Store.

2. **📱 iPhone (iOS 16, 17, 18+)**:
   - Layout compatto con barra di navigazione inferiore (**Tab Bar**) per utilizzo a una mano mentre cammini per la Città Universitaria:
     - **Dashboard**: panoramica rapida, prossime lezioni e scadenze.
     - **Orario**: orari settimanali, aule e nomi dei professori.
     - **Libretto**: CFU acquisiti, media ponderata e simulatore laurea.
     - **Trasporti**: Metro B Policlinico, tram, autobus e orario di partenza consigliato.
     - **Altro**: Appunti, task, pausa studio Pomodoro e impostazioni con i contatti dello sviluppatore.

3. **📱 iPad (iPadOS 16, 17, 18+)**:
   - Interfaccia ottimizzata per schermi ampi Retina con barra laterale retraibile e supporto a Apple Pencil per le note di laboratorio.

---

## ✨ Funzionalità su Misura per Farmacia Sapienza

### 1. 📋 Questionario Iniziale di Onboarding
- **Risolto il bug visivo della schermata pendolari**: il selettore dei mezzi è strutturato su una comoda griglia a schede dinamiche (*Metro B Policlinico*, *Tram 3/19 Regina Elena*, *Bus Atac 310/492*, *Treno FL1/FL2*, *Auto/Scooter*, *Bici/A piedi*) che non viene mai tagliata.
- **Pre-configurazione Farmacia Sapienza**:
  - Ateneo: *Sapienza Università di Roma*
  - Corso: *Farmacia (Ciclo Unico LM-13 - 300 CFU)*
  - Target Laurea e ore di studio giornaliere configurabili.

### 2. 👨‍🏫 Gestione Docenti & Cattedre per Materia
- Nella sezione **Orario & Lezioni**, pulsante dedicato **"Docenti Materie"** per visualizzare e impostare il nome del professore per ogni insegnamento (*Chimica Generale*, *Botanica*, *Chimica Organica*, *Anatomia*, *Galenica*, ecc.).
- Modifica rapida con un clic direttamente sulla scheda della lezione.

### 3. 📝 Gestione Appunti con Modelli di Farmacia
- **Modelli Pre-impostati**:
  - **Scheda Farmaco / Molecola**: sezioni pronte per *Principio Attivo*, *Classe Farmacoterapeutica*, *Meccanismo d'Azione*, *Indicazioni*, *Effetti Collaterali* e *Interazioni*.
  - **Laboratorio Galenico**: sezioni per *Composizione e Sostanze*, *Calcoli Tara ed Eccipienti*, *Procedimento di Allestimento*, *Saggi di Farmacopea Ufficiale (FU)*.
  - **Appunto Libero / Riassunto Lezione**: editor Markdown per appunti veloci e formule chimiche.

### 4. ☕ Sezione "Pausa & Focus Studio" con Motivazioni Personalizzate
- **Pausa Studio Dedicata**: timer per pausa breve (5 min) o stacco lungo (15 min) con indicazioni di benessere (idratazione, riposo visivo con la regola 20-20-20, stretching).
- **Motivazioni per la Pausa Studio**:
  - Frasi motivazionali e citazioni sul mestiere del farmacista e sulla vita universitaria a Roma.
  - Tasto **`🎲 Altra Frase`** per sfogliare le motivazioni.
  - Pulsante **`+ Aggiungi Motivazione`**: puoi scrivere e salvare le tue motivazioni personali (catalogate per *Farmacia*, *Traguardo Laurea*, *Relax & Benessere*, *Sapienza Life*, *Personale*).

### 5. 🚆 Trasporti & Pendolarismo verso la Sapienza
- Linee Metro e Bus pre-caricate:
  - **Metro B**: fermata *Policlinico* (5 min a piedi da CU019 Farmacia).
  - **Tram 3 / Tram 19**: fermata *Viale Regina Elena / Policlinico*.
  - **Bus 310**: fermata *Viale dell'Università / Cancelli Sapienza*.
  - **Bus 492**: fermata *Piazzale Aldo Moro / Ingresso Principale*.
- **Aggiunta Manuale di Autobus e Tratte**: inserisci nuove linee, orari di passaggio manuali, fermate di salita/discesa e calcolo automatico dell'orario di uscita da casa.

### 6. 🎓 Libretto Esami & Simulatore di Laurea
- Formula su 110 con base ponderata e slider punti tesi commissione per il traguardo dei 300 CFU.

---

## ⌨️ Scorciatoie da Tastiera macOS

| Scorciatoia | Sezione |
| :--- | :--- |
| <kbd>⌘</kbd> + <kbd>1</kbd> | Dashboard |
| <kbd>⌘</kbd> + <kbd>2</kbd> | Orario & Lezioni |
| <kbd>⌘</kbd> + <kbd>3</kbd> | Libretto Esami & Laurea |
| <kbd>⌘</kbd> + <kbd>4</kbd> | Appunti & Schede Farmaco |
| <kbd>⌘</kbd> + <kbd>5</kbd> | Scadenze & Infostud |
| <kbd>⌘</kbd> + <kbd>6</kbd> | Trasporti & Bus Atac |
| <kbd>⌘</kbd> + <kbd>7</kbd> | Pausa & Studio |
| <kbd>⌘</kbd> + <kbd>N</kbd> | Nuovo Appunto |
| <kbd>⌘</kbd> + <kbd>T</kbd> | Nuova Scadenza |

---

## 🛠️ Come Eseguire UniFlow

### Su macOS (MacBook Air/Pro M2)
Puoi avviare direttamente l'applicazione già compilata:
```bash
open build/UniFlow.app
```
Oppure ricompilarla con lo script incluso:
```bash
./build_app.sh
```

### Su iPhone o iPad
1. Apri la cartella di progetto in **Xcode**:
   ```bash
   open Package.swift
   ```
2. Nel selettore di destinazione in alto in Xcode, scegli il tuo dispositivo (**iPhone di Aldo** o un simulatore iPhone/iPad).
3. Premi **Run (<kbd>⌘</kbd> + <kbd>R</kbd>)** per installare e avviare l'app direttamente sul telefono o tablet.
