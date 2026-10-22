-- 1. Garante a criação do schema
CREATE SCHEMA IF NOT EXISTS silver;

-- 2. Apaga a tabela antiga se ela existir dentro do schema
DROP TABLE IF EXISTS silver.nutritional_information_cleaned CASCADE;

-- 3. Cria a nova tabela limpa
CREATE TABLE silver.nutritional_information_cleaned AS
SELECT
    -- ID Auto-incremental gerado para a camada Silver
    ROW_NUMBER() OVER () AS id_alimento,

    -- TRATAMENTO DE TEXTOS
    TRIM("Food")::VARCHAR(150) AS alimento,
    TRIM("Measure")::VARCHAR(50) AS medida,
    TRIM("Category")::VARCHAR(100) AS categoria,

    -- TRATAMENTO DE NUMÉRICOS
    -- 1. Gramas
    CASE 
        WHEN "Grams" IS NULL OR TRIM("Grams") IN ('', '?', 'N/A', '-', 'n/a', 't', 'T') THEN 0
        ELSE REPLACE(TRIM("Grams"), ',', '')::NUMERIC(10, 2)
    END AS peso_g,

    -- 2. Calorias
    CASE 
        WHEN "Calories" IS NULL OR TRIM("Calories") IN ('', '?', 'N/A', '-', 'n/a', 't', 'T') THEN 0
        ELSE REPLACE(TRIM("Calories"), ',', '')::INT
    END AS calorias_kcal,

    -- 3. Proteínas
    CASE 
        WHEN "Protein" IS NULL OR TRIM("Protein") IN ('', '?', 'N/A', '-', 'n/a', 't', 'T') THEN 0
        ELSE REPLACE(TRIM("Protein"), ',', '')::NUMERIC(10, 2)
    END AS proteina_g,

    -- 4. Gordura Total
    CASE 
        WHEN "Fat" IS NULL OR TRIM("Fat") IN ('', '?', 'N/A', '-', 'n/a', 't', 'T') THEN 0
        ELSE REPLACE(TRIM("Fat"), ',', '')::NUMERIC(10, 2)
    END AS gordura_total_g,

    -- 5. Gordura Saturada
    CASE 
        WHEN "Sat.Fat" IS NULL OR TRIM("Sat.Fat") IN ('', '?', 'N/A', '-', 'n/a', 't', 'T') THEN 0
        ELSE REPLACE(TRIM("Sat.Fat"), ',', '')::NUMERIC(10, 2)
    END AS gordura_saturada_g,

    -- 6. Fibras
    CASE 
        WHEN "Fiber" IS NULL OR TRIM("Fiber") IN ('', '?', 'N/A', '-', 'n/a', 't', 'T', 'a') THEN 0
        ELSE REPLACE(TRIM("Fiber"), ',', '')::NUMERIC(10, 2)
    END AS fibra_g,

    -- 7. Carboidratos
    CASE 
        WHEN "Carbs" IS NULL OR TRIM("Carbs") IN ('', '?', 'N/A', '-', 'n/a', 't', 'T') THEN 0
        ELSE REPLACE(TRIM("Carbs"), ',', '')::NUMERIC(10, 2)
    END AS carboidratos_g

    -- METADADO DE AUDITORIA
    _ingested_at

FROM bronze.nutritional_information_raw;