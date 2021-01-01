"Roma non è stata costruita in un giorno".
Cominceremo dalle basi. E la base di un computer è proprio il processore.
Il contenuto della scatolina vista nello scorso post è lo Zilog Z80, un processore progettato da Federico Faggin nella prima metà degli anni 70, ed utilizzato poi in innumerevoli computer e console, fino agli anni 90 (eh si, a quei tempi non usciva un processore l'anno...).
Questa CPU è ancora in produzione, sebbene "aggiornata" facendo uso della tecnologia CMOS, molto più efficiente e parca nei consumi. Il modello in mio possesso può essere clockato fino ad 8Mhz, ma se ne trovano modelli fino a 20Mhz! All'epoca una frequenza comune per questo processore era intorno ai 3Mhz (spesso 3,57 per utilizzare un solo cristallo sia per la CPU che per la [generazione di colore per il video](https://en.wikipedia.org/wiki/NTSC#Color_encoding) ).
Oggi, però, la faremo girare moooooolto più lenta.

Da dove cominciare? Per saperlo, bisogna chiederci quale sia il comportamento atteso di un processore. Non è la sede per una spiegazione approfondita, ma basti sapere che il processore (anche i più moderni) non fa altro che eseguire delle istruzioni. Una istruzione è un byte (o se preferite un numero da 0 a 255) che dice al processore cosa fare.
Questo viene ripetuto all'infinito, in un ciclo composto da tre fasi:
- Fetch (ottiene l'istruzione da eseguire dalla memoria)
- Decode (interpreta l'istruzione)
- Execute (la esegue)
Per la nostra prima prova abbiamo bisogno di sapere anche come funziona la memoria.
Ogni memoria (ROM, RAM, Flash...) è composta da una serie di posizioni che possono contenere dei valori. Si accede al contenuto di una posizione in base al suo indirizzo.
Quando il processore viene avviato, non fa altro che cominciare dalla prima posizione di memoria (0), leggere il contenuto (Fetch), capire cosa significa (Decode), eseguirlo (Execute) e passare alla successiva posizione di memoria (1), dove ricomincia da capo.
Ovviamente alcune istruzioni possono modificare questo flusso, ad esempio l'istruzione JP (Jump) dice al processore "Non andare a prendere la prossima posizione di memoria, ma salta alla posizione X".
Per questo motivo noi siamo interessati all'istruzione NOP, (No OPeration): questa istruzione non fa assolutamente nulla. Spreca un ciclo di cpu senza toccare nulla, per cui il processore andrà a cercare l'istruzione successiva nella posizione di memoria successiva.
Ci aspettiamo quindi di vedere i seguenti accessi alla memoria (a destra il valore binario):
0   00000000 00000000
1   00000000 00000001
2   00000000 00000010
3   00000000 00000011
4   00000000 00000100
5   00000000 00000101
etc etc ...



