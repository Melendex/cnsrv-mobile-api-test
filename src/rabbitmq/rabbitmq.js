const amqplib = require('amqplib');
const cron = require('node-cron');
const sharp = require("sharp");


const queueName = "images";
let conn;
let channel;
let queue;

const rabbitConnection = async() => {
    try {
        conn = await amqplib.connect(`amqp://${process.env.RABBITMQ_USERNAME}:${process.env.RABBITMQ_PASSWORD}@${process.env.RABBITMQ_HOST}:${process.env.RABBITMQ_PORT}/`);
        if (!conn) {
            throw new Error('RabbitMQ connection Failed');
        }

        channel = await conn.createChannel();
        if (!channel) {
            throw new Error('RabbitMQ crated channel Failed');;
        }
        queue = await channel.assertQueue(queueName);
        console.log('queue :', queue)
        if (!queue) {
            throw new Error('RabbitMQ create queue Failed');
        }
    } catch (error) {
        console.log(error)
    }



};
const addQueue = (item) => {
    return channel.sendToQueue(queueName, Buffer.from(JSON.stringify(item)));
    // return channel.sendToQueue(queueName, Buffer.from(item.toString()));
}

const complateQueue = async() => {
    await channel.consume(queueName, (msg) => {
        let dataMsg = JSON.parse(msg.content.toString());

        const base64 = dataMsg.selfi.data;
        // const image = sharp(base64).toFile('image.png');

        channel.cancel(msg.fields.consumerTag).then((res) => {
            channel.ack(msg)
        }).catch((err) => { console.log(err) })
        console.log('Queue Completed!! ')
    });

}

cron.schedule('*/30 * * * * *', () => {
    console.log('Entrando a Cron ⏱️')
    complateQueue()
    console.log('Saliendo de Cron ⏱️')
})

module.exports = { rabbitConnection, addQueue, complateQueue }