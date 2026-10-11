import React from 'react';
import { useApp } from '../context/AppContext';
import { Truck, CheckCircle2, Clock, MapPin, Package } from 'lucide-react';

export const TransporteurDashboard: React.FC = () => {
  const { shipments, updateShipmentStatus } = useApp();

  return (
    <div className="space-y-6 pb-20">
      <div className="rounded-3xl bg-gradient-to-r from-sky-500 via-blue-600 to-indigo-700 p-6 sm:p-8 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/20 text-xs font-black uppercase mb-2">
            <span>🚚 LOGISTIQUE & TRANSPORTEUR</span>
          </div>
          <h1 className="font-heading text-2xl sm:text-3xl font-black uppercase leading-tight">
            LIVRAISONS & APPROVISIONNEMENT CRÈCHE
          </h1>
          <p className="text-xs sm:text-sm text-sky-100 mt-1">
            Suivi des tournées, colis de couches et paniers repas bio
          </p>
        </div>
      </div>

      <div className="bg-white rounded-3xl p-5 sm:p-6 border border-sky-200 shadow-md space-y-4">
        <h3 className="font-heading font-black text-lg text-slate-900 uppercase">
          COLIS ET LIVRAISONS EN COURS
        </h3>

        <div className="space-y-3">
          {shipments.map((ship) => (
            <div
              key={ship.id}
              className="p-4 rounded-2xl border border-slate-200 bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
            >
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-2xl bg-sky-100 text-sky-700 flex items-center justify-center text-xl shrink-0">
                  📦
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-xs sm:text-sm text-slate-900 font-mono">
                      {ship.trackingNumber}
                    </span>
                    <span className="text-[10px] text-slate-400">({ship.weight} kg)</span>
                  </div>
                  <p className="text-xs text-slate-700 font-medium mt-0.5">
                    {ship.senderName} ➔ {ship.receiverName}
                  </p>
                  <p className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
                    <MapPin className="w-3 h-3 text-sky-600" />
                    <span>Destination : {ship.destinationAddress}</span>
                  </p>
                  {ship.notes && (
                    <p className="text-[11px] text-slate-500 italic mt-0.5">Note : {ship.notes}</p>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                {ship.status === 'delivered' ? (
                  <span className="px-3.5 py-1.5 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold flex items-center gap-1">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    <span>Livré</span>
                  </span>
                ) : (
                  <>
                    <button
                      onClick={() => updateShipmentStatus(ship.id, 'delivered')}
                      className="px-3 py-1.5 rounded-full bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs shadow-xs transition"
                    >
                      Marquer Livré
                    </button>
                    <button
                      onClick={() => updateShipmentStatus(ship.id, 'in_transit')}
                      className="px-3 py-1.5 rounded-full bg-sky-100 text-sky-800 font-bold text-xs hover:bg-sky-200 transition"
                    >
                      En transit
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
