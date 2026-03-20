import pandas as pd
from sqlalchemy import create_engine

DB_USER = "admin"
DB_PASS = "superhaslo123"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "data_engineering_db"

#Połączenie z bazą
engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

FILE_PATH = "2019-Nov.csv"
TABLE_NAME = "raw_events"

#Ładowanie danych w częściach
def load_in_chunks():
    chunk_size = 50000
    total_inserted = 0

    for i, chunk in enumerate(pd.read_csv(FILE_PATH, chunksize = chunk_size)):
        if_exists_action = 'replace' if i == 0 else 'append'

        chunk.to_sql(
            name = TABLE_NAME,
            con = engine,
            if_exists = if_exists_action,
            index = False
        )

        total_inserted += len(chunk)
        print(total_inserted)

if __name__ == "__main__":
    load_in_chunks()