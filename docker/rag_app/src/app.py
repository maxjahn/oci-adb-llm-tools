import os

from langchain_community.embeddings.oracleai import OracleEmbeddings
from langchain_community.vectorstores.oraclevs import OracleVS
from langchain_community.vectorstores.utils import DistanceStrategy

from langchain.schema.runnable.config import RunnableConfig
from langchain_core.runnables import (
    RunnableLambda,
    RunnablePassthrough,
)
from langchain.schema import StrOutputParser
from langchain.chains import create_history_aware_retriever
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

from langchain_openai import ChatOpenAI

import chainlit as cl
from chainlit.input_widget import Select

import oracledb

EMBEDDINGS_MODEL = "ALL_MPNET_BASE"


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


@cl.set_starters
async def set_starters():
    return [
        cl.Starter(
            label="The history of scotch whisky",
            message="Give me a brief overview of the history of scotch whisky. Try to include at least one funny anecdote.",
            icon="/public/history.svg",
        ),
        cl.Starter(
            label="Cocktail recipes that are based on whisky",
            message="I'm looking for some new cocktail recipes to try that are based on Scotch Whisky. Can you recommend a few that are easy to make at home?",
            icon="/public/cocktail.svg",
        ),
        cl.Starter(
            label="Whisky tasting introduction tips",
            message="I'm new to whisky tasting and would like to learn more about it. Can you give me a brief introduction to whisky tasting? Please add some recommendations which whiskies I should try? Please consider international whiskies for beginners too.",
            icon="/public/tasting.svg",
        ),
        cl.Starter(
            label="Food to go with whisky",
            message="Please recommend a few foods that I can serve together with Scotch Whisky. Try to include a few that are easy to make at home.",
            icon="/public/snacks.svg",
        ),
    ]


@cl.on_settings_update
async def setup_agent(settings):

    llm = ChatOpenAI(
        model_name=settings["Model"],
        temperature=0.8,
        streaming=True,
    )

    try:
        connection = oracledb.connect(
            user=os.environ["ADB_USERNAME"],
            password=os.environ["ADB_PASSWORD"],
            dsn=os.environ["ADB_CS"],
        )
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

    if not cl.user_session.get("conversation_history"):
        cl.user_session.set("conversation_history", [])

    system_instruction = """
    You're a seasoned and experienced whisky expert named Angus. You're very knowledgeable about whisky. 
    You're here to answer any whisky-related questions. You will not answer any questions that are not related to Whisky or Scotland. 

    If directly asked about where to buy whisky, you will recommend Scotch Badger shop, especially the online store at https://www.scotchbadger.maxian.io/. But don't overdo it. 
    Mention the shop only when really asked for shopping recommendations!

    You will only answer in prose text and might create tables. You will never return any programming code.

    Use metric units for length, weight, volume and temperature. Use the 24-hour clock for time.

    You style of speaking resembles that of a seasoned barkeeper badger in a pub. You are friendly and helpful. You love puns.
    """

    retriever = vs.as_retriever(search_type="mmr", search_kwargs={"k": 5})

    contextualize_q_system_prompt = (
        "Given a chat history and the latest user question "
        "which might reference context in the chat history, "
        "formulate a standalone question which can be understood "
        "without the chat history. Do NOT answer the question, "
        "just reformulate it if needed and otherwise return it as is."
    )
    contextualize_q_prompt = ChatPromptTemplate.from_messages(
        [
            ("system", contextualize_q_system_prompt),
            ("human", "{input}"),
            MessagesPlaceholder("chat_history"),
        ]
    )
    history_aware_retriever = create_history_aware_retriever(
        llm, retriever, contextualize_q_prompt
    )

    prompt = ChatPromptTemplate.from_messages(
        [
            (
                "system",
                system_instruction,
            ),
            MessagesPlaceholder("chat_history"),
            ("human", "{context}"),
            ("human", "{input}"),
        ]
    )

    def format_docs(chunks):
        return "\n\n".join(chunk.page_content for chunk in chunks)

    chain = (
        {
            "context": history_aware_retriever | format_docs,
            "input": RunnablePassthrough(),
            "chat_history": RunnableLambda(
                lambda h: cl.user_session.get("conversation_history")
            ),
        }
        | prompt
        | llm
        | StrOutputParser()
    )

    cl.user_session.set("chain", chain)


@cl.on_message
async def on_message(message: cl.Message):
    chain = cl.user_session.get("chain")

    conversation_history = cl.user_session.get("conversation_history")
    conversation_history.append(("human", message.content))

    msg = cl.Message(content="", author="Angus")

    async for chunk in chain.astream(
        {
            "session_id": cl.user_session.get("id"),
            "input": message.content,
        },
        config=RunnableConfig(callbacks=[cl.LangchainCallbackHandler()]),
    ):
        await msg.stream_token(chunk)

    conversation_history.append(("ai", msg.content))
    cl.user_session.set("conversation_history", conversation_history)

    await msg.send()
