import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Package, Plus, CheckCircle2, TrendingUp, Sparkles } from 'lucide-react';

export const FournisseurDashboard: React.FC = () => {
  const { shipments, addShipment } = useApp();
  const [tracking, setTracking] = useState('');
  const [receiver, setReceiver] = useState('Crèche Les Petits Oursons');
  const [notes, setNotes] = useState('Paniers de compotes et légumes de saison');
  const [weight, setWeight] = useState(15);
  const [isAdding, setIsAdding] = useState(false);

  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    addShipment({
      trackingNumber: tracking || `BIO-LIV-${Math.floor(1000 + Math.random() * 9000)}`,
      senderName: 'Fournisseur Repas Bio & Puériculture',
      receiverName: receiver,
      transporteurName: 'Yassine Benali (Logistique Express)',
      status: 'pending',
      originAddress: 'Ferme Bio de Saclay',
      destinationAddress: '28 Boulevard des Enfants, Paris',
      weight,
      estimatedDelivery: 'Demain matin 08h30',
      notes,
    });
    setTracking('');
    setIsAdding(false);
  };

  return (
    <div className="space-y-6 pb-20">
      <div className="rounded-3xl bg-gradient-to-r from-purple-600 via-violet-600 to-indigo-700 p-6 sm:p-8 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/20 text-xs font-black uppercase mb-2">
            <span>📦 FOURNISSEUR REPAS & MATÉRIEL</span>
          </div>
          <h1 className="font-heading text-2xl sm:text-3xl font-black uppercase leading-tight">
            COMMANDE ALIMENTATION BIO & PUÉRICULTURE
          </h1>
          <p className="text-xs sm:text-sm text-purple-100 mt-1">
            Gestion des expéditions de repas frais, couches et fournitures pédagogiques
          </p>
        </div>
      </div>

      <div className="bg-white rounded-3xl p-5 sm:p-6 border border-purple-200 shadow-md space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="font-heading font-black text-lg text-slate-900 uppercase">
            COMMANDES EXPÉDIÉES VERS LA CRÈCHE
          </h3>
          <button
            onClick={() => setIsAdding(!isAdding)}
            className="px-3.5 py-1.5 rounded-full bg-purple-600 text-white font-bold text-xs hover:bg-purple-700 transition"
          >
            {isAdding ? 'Fermer' : '+ Nouvelle expédition'}
          </button>
        </div>

        {isAdding && (
          <form onSubmit={handleAdd} className="p-4 bg-purple-50/50 rounded-2xl border border-purple-200 space-y-3">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Désignation marchandise :</label>
                <input
                  type="text"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full p-2.5 rounded-xl border border-slate-200 text-xs bg-white"
                  placeholder="Ex: 50 repas bio déjeuners et goûters"
                />
              </div>
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Poids total (kg) :</label>
                <input
                  type="number"
                  value={weight}
                  onChange={(e) => setWeight(Number(e.target.value))}
                  className="w-full p-2.5 rounded-xl border border-slate-200 text-xs bg-white"
                />
              </div>
            </div>
            <button
              type="submit"
              className="w-full py-2.5 rounded-xl bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs shadow-xs transition"
            >
              Enregistrer l'expédition
            </button>
          </form>
        )}

        <div className="space-y-3">
          {shipments.map((s) => (
            <div
              key={s.id}
              className="p-3.5 rounded-2xl border border-slate-200 bg-slate-50 flex items-center justify-between text-xs"
            >
              <div>
                <span className="font-bold text-slate-900 font-mono">{s.trackingNumber}</span>
                <p className="text-slate-600 mt-0.5">{s.notes || 'Fournitures crèche'}</p>
                <span className="text-[10px] text-slate-400">Poids : {s.weight} kg</span>
              </div>
              <span
                className={`px-3 py-1 rounded-full text-[10px] font-bold ${
                  s.status === 'delivered' ? 'bg-emerald-100 text-emerald-800' : 'bg-purple-100 text-purple-800'
                }`}
              >
                {s.status === 'delivered' ? 'Livré ✅' : 'En transit 🚛'}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
