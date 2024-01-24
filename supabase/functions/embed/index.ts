import { env, pipeline } from '@xenova/transformers';

import { createClient } from '@supabase/supabase-js';

// Configuration for Deno runtime
env.useBrowserCache = false;
env.allowLocalModels = false;

const generateEmbedding = await pipeline(
  'feature-extraction',
  'Supabase/gte-small'
);
// These are automatically injected
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');

Deno.serve(async (req) => {
  if (!supabaseUrl || !supabaseAnonKey) {
    return new Response(
      JSON.stringify({
        error: 'Missing environment variables.',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
  const authorization = req.headers.get('Authorization');

  if (!authorization) {
    return new Response(
      JSON.stringify({ error: `No authorization header passed` }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        authorization,
      },
    },
    auth: {
      persistSession: false,
    },
  });
  const { ids, table, contentColumn, embeddingColumn } = await req.json();

  const { data: rows, error: selectError } = await supabase
    .from(table)
    .select(`id, ${contentColumn}` as '*')
    .in('id', ids)
    .is(embeddingColumn, null);

  if (selectError) {
    return new Response(JSON.stringify({ error: selectError }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  for (const row of rows) {
    //batch of 10 in this case
    const { id, [contentColumn]: content } = row;

    if (!content) {
      console.error(`No content available in column '${contentColumn}'`);
      continue;
    }
    // we created func generateEmbedding in pipeline (huggingface)
    const output = await generateEmbedding(content, {
      pooling: 'mean', //pooling to one from whole bunch of tokens
      normalize: true, // if you think about your vector, it got a direction and length in whatever n dimensional space it's in and if you normalize that length, that is if you take that length and turn it down to a length of 1, that turns it into a unit vector and that's called a normalized vector. why it is important, later on when we calculate similarity so if you recall me mentioning cosine similarity, cosine similarity is a measure of the angle between two vectors and if you have two vectors that are both unit vectors, then the cosine similarity is just the dot product of those two vectors. so it's a very simple calculation and it's very fast to do. so that's why we normalize the vector.
    });
    //the second param we want to do 2 things: 1. set pooling to mean 2. normalize to true

    const embedding = JSON.stringify(Array.from(output.data));
    // stringify or casting to string
    const { error } = await supabase
      .from(table)
      .update({
        [embeddingColumn]: embedding,
      })
      .eq('id', id); //filtering by id

    if (error) {
      console.error(
        `Failed to save embedding on '${table}' table with id ${id}`
      );
    }

    console.log(
      `Generated embedding ${JSON.stringify({
        table,
        id,
        contentColumn,
        embeddingColumn,
      })}`
    );
  }
});
