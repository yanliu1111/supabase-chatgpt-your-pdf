-- Two parameters, query embedding that we want to compare against our database to see what matches with it, specifically in our context whatever typing in chat, this will be converted into an embedding and that embedding will pass into this function as the first argument, the second argument is the match threshold, this is a float between 0 and 1, the closer to 1 the more similar the embeddings have to be to be considered a match
-- in a new vector data type, pgvector introduces three new operators, <#> the operator looks like this, pgvector turns all this new Vector search vector similarity logic into plain SQL
-- <#> negative distance, because order by ascending, the smaller the distance the closer the match.
create or replace function match_document_sections(
      embedding vector(384), -- match the dimension size
      match_threshold float
    )
    returns setof document_sections
    language plpgsql
    as $$
    #variable_conflict use_variable
    begin
      return query
      select *
      from document_sections
      where document_sections.embedding <#> embedding < -match_threshold -- negative to negative
    	order by document_sections.embedding <#> embedding;
    end;
    $$;