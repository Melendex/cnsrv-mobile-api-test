const mongoose = require("mongoose");

const branchSchema = new mongoose.Schema({
   
  _id: { type: Number },
  nombre: { type: String, trim: true },
  alias: { type: String, trim: true },
  colonia: [],
  municipio: [],
  estado: [],
  pais: [],
  direccion: { type: String, trim: true },
  codigo_postal: { type: String, trim: true },
  enabled: { type: Boolean, default: false },
});

const Branch = mongoose.model("Branch", branchSchema);
module.exports = Branch;
