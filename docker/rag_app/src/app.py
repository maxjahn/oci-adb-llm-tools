import os
from typing import List

from langchain_core.documents import Document
from langchain.prompts import PromptTemplate
from langchain.memory import ConversationBufferMemory

from langchain_openai import ChatOpenAI

from langchain_community.embeddings.oracleai import OracleEmbeddings
from langchain_community.vectorstores.oraclevs import OracleVS
from langchain_community.vectorstores.utils import DistanceStrategy
from langchain_community.chat_message_histories import ChatMessageHistory

from langchain.chains import ConversationalRetrievalChain

import chainlit as cl
from chainlit.action import Action
from chainlit.input_widget import Select, Switch, Slider

import oracledb


EMBEDDINGS_MODEL = "ALL_MPNET_BASE"
SHOW_SOURCE = False

try:
    connection = oracledb.connect(user=os.environ["ADB_USERNAME"], password=os.environ["ADB_PASSWORD"], dsn=os.environ["ADB_CS"])
    print("Connection successful!")

except Exception as e:
    print("Connection failed!")
    quit()

embedder_params = {"provider": "database", "model": EMBEDDINGS_MODEL}
embedder = OracleEmbeddings(conn=connection, params=embedder_params)
vs = OracleVS(
    embedding_function=embedder,
    client=connection,
    table_name="reviews_vs",
    distance_strategy=DistanceStrategy.DOT_PRODUCT,
)

@cl.on_chat_start
async def start():
    settings = await cl.ChatSettings(
        [
            Select(
                id="Model",
                label="Model",
                values=[
                    "gpt-4",
                    "gpt-3.5",
                    "gpt-3.5-turbo",
                ],
                initial_index=0,
            )
        ]
    ).send()
    await setup_agent(settings)


@cl.on_settings_update
async def setup_agent(settings):

    llm = ChatOpenAI(model_name=settings["Model"], temperature=0.8, streaming=True)

    await cl.Avatar(
        name="Nepomuk",
        url="/public/logo_dark.png",
    ).send()

    message_history = ChatMessageHistory()

    memory = ConversationBufferMemory(
        memory_key="chat_history",
        output_key="answer",
        chat_memory=message_history,
        return_messages=True,
    )

    # Define your system instruction
    system_instruction = "You're a seasoned and experienced whisky expert. You're very knowledgeable about whisky. You're here to answer any whisky-related. You style of speaking resembles that of a seasoned barkeeper in a pub."

    # Define your template with the system instruction
    template = (
        f"{system_instruction} "
        "Combine the chat history and follow up question into "
        "a standalone question. Chat History: {chat_history}"
        "Follow up question: {question}"
    )

    # Create the prompt template
    condense_question_prompt = PromptTemplate.from_template(template)

    retriever = vs.as_retriever()
    
    # TODO: rewrite in LCEL 
    # chain = condense_question_prompt | retriever | llm | memory | cl.Text()

    chain = ConversationalRetrievalChain.from_llm(
        llm,
        chain_type="stuff",
        retriever=retriever,
        condense_question_prompt=condense_question_prompt,
        memory=memory,
        return_source_documents=True,
        return_generated_question=True,
        rephrase_question=True,
    )
    
    cl.user_session.set("chain", chain)


@cl.on_message
async def on_message(message: cl.Message):
    chain = cl.user_session.get("chain")  # type: ConversationalRetrievalChain
    cb = cl.AsyncLangchainCallbackHandler()

    res = await chain.acall(message.content, callbacks=[cb])
    answer = res["answer"]
    source_documents = res["source_documents"]  # type: List[Document]

    text_elements = []  # type: List[cl.Text]

    if SHOW_SOURCE:
        if source_documents:
            for source_idx, source_doc in enumerate(source_documents):

                source_name = f"[{source_idx}]"
                # Create the text element referenced in the message
                text_elements.append(
                    cl.Text(content=source_doc.page_content, name=source_name)
                )
            source_names = [text_el.name for text_el in text_elements]

            if source_names:
                answer += f"\nSources: {', '.join(source_names)}"
                answer += ""
            else:
                answer += "\nNo sources found"

    await cl.Message(content=answer, elements=text_elements, author="Nepomuk").send()








