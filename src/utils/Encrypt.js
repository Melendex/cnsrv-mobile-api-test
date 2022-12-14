const FileSystem = require("fs"),
      Crypto = require("crypto"),
      dsConfig = require('./dsConfig').config;

class Encrypt {

    constructor(filePath) {
        this.filePath = filePath;
        this.password = dsConfig.tokenSecret;
    }

    encrypt(data) {
        try {
            var cipher = Crypto.createCipher('aes-256-cbc', this.password);
            var encrypted = Buffer.concat([cipher.update(Buffer.from(JSON.stringify(data))), cipher.final()]);
            FileSystem.writeFileSync(this.filePath, encrypted);
            return { message: "Encrypted!" };
        } catch (exception) {
            throw new Error(exception.message);
        }
     }

    decrypt() {
        try {
            var data = FileSystem.readFileSync(this.filePath);
            var decipher = Crypto.createCipher("aes-256-cbc", this.password);
            var decrypted = Buffer.concat([decipher.update(data), decipher.final()]);
            return JSON.parse(decrypted.toString());
        } catch (exception) {
            throw new Error(exception.message);
        }
     }
}

exports.Encrypt = Encrypt;