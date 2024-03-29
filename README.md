<img alt="pgvector to Prod in 2 hours" src="./assets/hero.png">
<h1 align="center">Workshop: pgvector to Prod in 2 hours</h1>

<p align="center">
Create a production-ready MVP for securely chatting with your documents.
</p>

### ☑️ Learning from 👉 [HERE](https://github.com/gregnr/chatgpt-your-files)

### ☑️ I kept my learning 📝notes in different branches, just follow the GR great tutorial and you will learn everything.

### ☑️ From this tutorial you will learn:

- Supabase
- Database migration
- The structure of how to use retrival augmented generation (RAG) to process your files, and query smaller meaningful document sections.
- You will learn pgvector, how to index your text, and create edge functions to process the markdown files into document_sections table.
- You will learn Embedding from GR ❤️, highly recommend his [Embedding teaching](https://www.youtube.com/watch?v=Yhtjd7yGGGA&t=26s&ab_channel=RabbitHoleSyndrome).
- The interesting step is generating the ueser message embedding in the frontend. Then determine the similarity with markdown files embedding.

### 📑Notes files:<br>

The first time following the learning using git branches, I like this way, time efficient and more focus on the knowledge and code logic. The code edits in the following <span style="color:blue">**Branches**</span>: <br>

- **Step-2**
  - Readme
  - app/files/pages.tsx
  - supabase/functions/process/index.js
  - supbase/seed.sql
  - supabase/migrations/documents.sql<br>
- **Step-3**
  - Readme
  - supabase/migrations/embed.sql<br>
- **Step-4**
  - Readme
  - next.config.js
  - app/chat/pages.tsx
  - supabase/migrations/match.sql
  - supabase/functions/chat/index.tsx <br>
- **Step-5**
  - Generate DB schema typescript type, add \<Database> generic and type error check. <br>
