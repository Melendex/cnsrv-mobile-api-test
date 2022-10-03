const express = require('express');
const docusign = require('docusign-esign');
const fs = require('fs');
const router = new express.Router();
const dsConfig = require('./../utils/dsConfig').config;
const apiClient = new docusign.ApiClient();

apiClient.setBasePath('https://demo.docusign.net/restapi');
apiClient.setOAuthBasePath('account-d.docusign.com');
const dsUserID = process.env.DOCUSIGN_USER_ID;
const dsClientId = process.env.DOCUSIGN_INTEGRATION_KEY;
const keySecrect = process.env.DOCUSIGN_PRIVATE_KEY_3.replace(/\n/g, '\n');

const rsaKey = Buffer.from(keySecrect);
const jwtLifeSec = 10 * 60;

apiClient.requestJWTUserToken(dsClientId, dsUserID, 'signature', rsaKey, jwtLifeSec)
    .then((results) => {
        dsConfig.dsAccessToken = results.body.access_token;
        console.log('DucuSing SignIn 👌');
        apiClient.addDefaultHeader('Authorization', `Bearer ${dsConfig.dsAccessToken}`);

        let envelopeApi = new docusign.EnvelopesApi(apiClient);
        let env = new docusign.Envelope();
        env.status = 'voided';
        env.voidedReason = 'Declined Offter';

        apiClient.getUserInfo(dsConfig.dsAccessToken)
            .then((result) => {
                dsConfig.dsAccountId = result.accounts[0].accountId;
                console.log('User information saved 👌');
            }).catch((error) => { console.log(error); });
    });

router.post('/ds/testSendContract', async (req, res) => {
    try {
        const { users, documents } = req.body;
        let envelopeApi = new docusign.EnvelopesApi(apiClient);

        const doc = fs.readFileSync('./blank.pdf');
        const docBase64 = Buffer.from(doc).toString('base64');

        const envDefn = {
            documents:
                documents.map((doc, idx) => {
                    const docObj = {
                        documentBase64: doc.base64,
                        documentId: `${idx + 1}`,
                        fileExtension: doc.fileExtension,
                        name: doc.name
                    }

                    return docObj;
                }),
            emailSubject: 'Prueba de envio de Contrato CNSRV',
            recipients: {
                signers: 
                users.map((user, idx) => {
                    const userObj = {
                        email: user.email,
                        name: user.name,
                        recipientId: `${idx + 1}`,
                        tabs: {
                            signHereTabs:
                                idx != 1 ?
                                    [
                                        {
                                            documentId: "1",
                                            name: "RECIPIENT 1 SIGN 1",
                                            // optional: "false",
                                            pageNumber: "10",
                                            recipientId: "1",
                                            scaleValue: 1,
                                            tabLabel: "signer1_doc2",
                                            xPosition: "392",
                                            yPosition: "535"
                                        },
                                        {
                                            documentId: "2",
                                            name: "RECIPIENT 1 SIGN 2",
                                            // optional: "false",
                                            pageNumber: "1",
                                            recipientId: "1",
                                            scaleValue: 1,
                                            tabLabel: "signer1_doc2",
                                            xPosition: "273",
                                            yPosition: "335"
                                        },
                                        {
                                            documentId: "3",
                                            name: "RECIPIENT 1 SIGN 3",
                                            // optional: "false",
                                            pageNumber: "2",
                                            recipientId: "1",
                                            scaleValue: 1,
                                            tabLabel: "signer1_doc2",
                                            xPosition: "261",
                                            yPosition: "293"
                                        }

                                    ] :
                                    [
                                        {
                                            documentId: "1",
                                            name: "RECIPIENT 2 SIGN 1",
                                            pageNumber: "10",
                                            recipientId: "2",
                                            scaleValue: 1,
                                            tabLabel: "signer1_doc2",
                                            xPosition: "124",
                                            yPosition: "535"
                                        }
                                    ]
                        }
                    }

                    return userObj;
                })
            },
            status: 'sent'
        }

        const optsEnvelope = {
            cdseMode: '',
            changeRoutingOrder: 'true',
            completedDocumentsOnly: 'false',
            mergeRolesOnDraft: '',
            tabLabelExactMatches: '',
            envelopeDefinition: envDefn
        }

        envelopeApi.createEnvelope(dsConfig.dsAccountId, optsEnvelope)
            .then((result) => {
                res.status(200).send(result);
                // envelopeApi.getEnvelope(dsConfig.dsAccountId)
            }).catch((err) => {
                console.log(err.response.body)
                // throw new Error(err);
            })
    } catch (error) {
        res.status(400).send(error.message)
    }
})

router.get('/ds/getEnvelope', (req, res) => {
    try {
        const {envelopeId} = req.query;

        let envelopeApi = new docusign.EnvelopesApi(apiClient);

        envelopeApi.getEnvelope(dsConfig.dsAccountId, envelopeId,{})
            .then((result) => {
                res.status(200).send(result)
            }).catch((err) => {
                throw new Error(err)
            })

    } catch (error) {
        res.status(400).send(error.message)
    }
})


module.exports = router;