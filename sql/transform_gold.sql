-- 1. Cria o Schema Gold primeiro
CREATE SCHEMA IF NOT EXISTS gold;

-- 2. DIMENSÃO CATEGORIA
DROP TABLE IF EXISTS gold.dim_categoria CASCADE;

CREATE TABLE gold.dim_categoria AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY categoria_nome) AS id_categoria,
    categoria_nome
FROM (
    SELECT DISTINCT 
        TRIM(categoria_item) AS categoria_nome
    FROM 
        silver.nutritional_information_cleaned,
        UNNEST(STRING_TO_ARRAY(categoria, ',')) AS categoria_item
    WHERE 
        categoria IS NOT NULL 
        AND TRIM(categoria) <> ''
) subquery;

ALTER TABLE gold.dim_categoria 
ADD CONSTRAINT pk_dim_categoria PRIMARY KEY (id_categoria);


-- 3. DIMENSÃO ALIMENTO
DROP TABLE IF EXISTS gold.dim_alimento CASCADE;

CREATE TABLE gold.dim_alimento AS
SELECT
    ROW_NUMBER() OVER (ORDER BY alimento) AS id_alimento,
    alimento,
    medida,
    categoria AS categoria_origem
FROM (
    SELECT DISTINCT
        alimento,
        medida,
        categoria
    FROM silver.nutritional_information_cleaned
    WHERE alimento IS NOT NULL AND TRIM(alimento) <> ''
) subquery;

ALTER TABLE gold.dim_alimento 
ADD CONSTRAINT pk_dim_alimento PRIMARY KEY (id_alimento);


-- 4. TABELA FATO NUTRIÇÃO
DROP TABLE IF EXISTS gold.fato_nutricao CASCADE;

CREATE TABLE gold.fato_nutricao AS
SELECT
    ROW_NUMBER() OVER () AS id_fato,
    da.id_alimento,
    dc.id_categoria,
    
    -- MÉTRICAS NUMÉRICAS
    s.peso_g,
    s.calorias_kcal,
    s.proteina_g,
    s.gordura_total_g,
    s.gordura_saturada_g,
    s.fibra_g,
    s.carboidratos_g,
    
    s._ingested_at

FROM silver.nutritional_information_cleaned s
LEFT JOIN gold.dim_alimento da 
    ON s.alimento = da.alimento 
   AND s.medida = da.medida
LEFT JOIN LATERAL UNNEST(STRING_TO_ARRAY(s.categoria, ',')) AS cat_item ON TRUE
LEFT JOIN gold.dim_categoria dc 
    ON dc.categoria_nome = TRIM(cat_item);

-- 5. CONSTRAINTS (Chaves Primárias e Estrangeiras)
ALTER TABLE gold.fato_nutricao 
ADD CONSTRAINT pk_fato_nutricao PRIMARY KEY (id_fato);

ALTER TABLE gold.fato_nutricao 
ADD CONSTRAINT fk_fato_alimento FOREIGN KEY (id_alimento) REFERENCES gold.dim_alimento(id_alimento);

ALTER TABLE gold.fato_nutricao 
ADD CONSTRAINT fk_fato_categoria FOREIGN KEY (id_categoria) REFERENCES gold.dim_categoria(id_categoria);