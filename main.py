import logging

# Logging settings
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def say_hello():
    return "Hello World"

def handler(event, context):
    logger.info("Started lambda")
    resp = say_hello()
    logger.info("Ending lambda")
    return resp

if __name__ == "__main__":
    handler(None, None)
