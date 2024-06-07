
import oracledb
import os
import sys

from langchain_community.document_loaders.oracleai import (
    OracleDocLoader,
    OracleTextSplitter,
)
from langchain_community.embeddings.oracleai import OracleEmbeddings
from langchain_community.utilities.oracleai import OracleSummary
#from langchain_community.vectorstores import oraclevs
from langchain_community.vectorstores.oraclevs import OracleVS
from langchain_community.vectorstores.utils import DistanceStrategy
from langchain_core.documents import Document


adb_dsn = os.environ['ADB_CS']
adb_username = os.environ['ADB_USERNAME']
adb_password = os.environ['ADB_PASSWORD']

try:
    connection=oracledb.connect(
     user=adb_username,
     password=adb_password,
     dsn=adb_dsn)
    print("Connection successful!")
    
except Exception as e:
    print("Connection failed!")
    quit()
    
embedder_params = {"provider": "database", "model": "bge_micro"}
embedder = OracleEmbeddings(conn=connection, params=embedder_params)


vs = OracleVS(embedding_function=embedder, client=connection, table_name="reviews_vs", distance_strategy=DistanceStrategy.DOT_PRODUCT)


query = "which whisky is suitable for a scotch expert?"
#filter = {"document_id": ["1"]}

# Similarity search without a filter
#print(vs.similarity_search(query, 3))

# Similarity search with relevance score with filter
print(vs.similarity_search_with_score(query, 3))
