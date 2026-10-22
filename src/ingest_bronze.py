import os
import pandas as pd
from datetime import datetime
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

DB_USER = os.getenv("POSTGRESQL_USERNAME")
DB_PASS = os.getenv("POSTGRESQL_PASSWORD")
DB_HOST = os.getenv("POSTGRES_HOST", "localhost")
DB_PORT = os.getenv("POSTGRES_PORT", "5432")
DB_NAME = os.getenv("POSTGRESQL_DATABASE")

DATABASE_URL = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def run_ingestion():
    csv_path = "data/raw/nutrients_csvfile.csv"

    if not os.path.exists(csv_path):
        print(f"Erro: Arquivo '{csv_path}' não encontrado.")
        return
    
    print("Iniciando leitura do CSV...")
    df = pd.read_csv(csv_path, dtype=str)
    
    df["_ingested_at"] = datetime.now()
    
    print(f"Total de registros lidos: {len(df)}")

    engine = create_engine(DATABASE_URL)

    with engine.connect() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS bronze;"))
        conn.commit()

    print("Escrevendo dados na camada Bronze (PostgreSQL)...")
    df.to_sql(
        name="nutritional_information_raw",  
        con=engine,
        schema="bronze",
        if_exists="replace",
        index=False,
        chunksize=10000
    )
    
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM bronze.nutritional_information_raw;"))
        count = result.scalar()
        print(f"Ingestão concluída com sucesso! Total de linhas na tabela bronze.nutritional_information_raw: {count}")

if __name__ == "__main__":
    run_ingestion()