import os
import sys

import oracledb
from langchain_community.document_loaders.oracleai import (
    OracleDocLoader,
    OracleTextSplitter,
)
from langchain_community.embeddings.oracleai import OracleEmbeddings
from langchain_community.utilities.oracleai import OracleSummary
from langchain_community.vectorstores.oraclevs import OracleVS
from langchain_community.vectorstores.utils import DistanceStrategy
from langchain_core.documents import Document

adb_dsn = os.environ["ADB_CS"]
adb_username = os.environ["ADB_USERNAME"]
adb_password = os.environ["ADB_PASSWORD"]
embedding_model = "ALL_MPNET_BASE_V2"

try:
    connection = oracledb.connect(user=adb_username, password=adb_password, dsn=adb_dsn)
    print("Connection successful!")

except Exception as e:
    print("Connection failed!")
    quit()

embedder_params = {"provider": "database", "model": embedding_model}
embedder = OracleEmbeddings(conn=connection, params=embedder_params)

# create Oracle AI Vector Store
loader_params = {
    "owner": "vector",
    "tablename": "reviews",
    "colname": "description",
}
summary_params = {
    "provider": "database",
    "glevel": "S",
    "numParagraphs": 1,
    "language": "english",
}
splitter_params = {"normalize": "all"}

# instantiate loader, summary, splitter, and embedder
loader = OracleDocLoader(conn=connection, params=loader_params)
summary = OracleSummary(conn=connection, params=summary_params)
splitter = OracleTextSplitter(conn=connection, params=splitter_params)

docs = loader.lazy_load()

# process the documents
chunks_with_mdata = []
for id, doc in enumerate(docs, start=1):
    # summ = summary.get_summary(doc.page_content)

    print(f"Processing document {id}")
    # print(doc)
    chunks = splitter.split_text(doc.page_content)

    for ic, chunk in enumerate(chunks, start=1):
        chunk_metadata = doc.metadata.copy()
        # chunk_metadata["id"] = chunk_metadata["_oid"] + "$" + str(id) + "$" + str(ic)
        chunk_metadata["document_id"] = str(id)
        # chunk_metadata["document_summary"] = str(summ[0])
        chunks_with_mdata.append(
            Document(page_content=str(chunk), metadata=chunk_metadata)
        )

print(f"Number of total chunks with metadata: {len(chunks_with_mdata)}")

# create Oracle AI Vector Store
vs = OracleVS.from_documents(
    chunks_with_mdata,
    embedder,
    client=connection,
    table_name="reviews_oravs",
    distance_strategy=DistanceStrategy.COSINE,
)

# query = "which whisky has a taste of vanilla?"
# filter = {"document_id": ["1"]}

# Similarity search without a filter
# print(vs.similarity_search(query, 3))

# Similarity search with relevance score with filter
# print(vs.similarity_search_with_score(query, 1))
