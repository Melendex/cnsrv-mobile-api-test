const connectionSQL = require("./../db/connSQL");
const sql = require('mssql');
let pool;
const createPool = async () => {
    pool = await connectionSQL();
};
createPool();

function extractor(nameProcedure, nomRows) {

    return new Promise( async(resolve, reject) => {
        try {
            let rows;
            let initialRows = 0;
            let datos = [];

            do {
                const result = await pool.request()
                    .output('totalRows')
                    .input('initial', sql.Int, initialRows)
                    .input('numRows', sql.Int, nomRows)
                    .execute(nameProcedure);
                initialRows = initialRows + nomRows;

                datos = datos.concat(result.recordset)

                if (!rows) rows = parseInt(result.output.totalRows);
                rows = rows - nomRows;
            } while (rows > 0);

            resolve(datos);
        } catch (error) {
            reject(error.message);
        }
    });
}

module.exports = extractor