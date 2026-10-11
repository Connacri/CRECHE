import React from 'react';
import { useApp } from '../context/AppContext';
import { QrCodeDisplay } from './QrCodeDisplay';
import { X, ShieldCheck, Heart, Phone, AlertCircle } from 'lucide-react';

interface ChildQrModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const ChildQrModal: React.FC<ChildQrModalProps> = ({ isOpen, onClose }) => {
  const { selectedChild } = useApp();

  if (!isOpen || !selectedChild) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-150">
      <div className="relative w-full max-w-sm bg-white rounded-3xl shadow-2xl border border-amber-300 overflow-hidden flex flex-col text-center">
        {/* Header */}
        <div className="p-4 bg-gradient-to-r from-amber-400 to-[#FFB703] border-b border-amber-300 flex items-center justify-between text-slate-900">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-amber-900" />
            <h3 className="font-heading font-black text-sm uppercase tracking-wide">
              BADGE DE SÉCURITÉ QR
            </h3>
          </div>
          <button
            onClick={onClose}
            className="w-7 h-7 rounded-full bg-white/80 hover:bg-white text-slate-800 flex items-center justify-center transition shadow-xs"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 flex flex-col items-center bg-[#FFFDF7]">
          {/* Child avatar */}
          <div className="relative -mt-2 mb-3">
            <img
              src={selectedChild.photoUrl || 'https://images.unsplash.com/photo-1543332164-6e82f355badc?w=120'}
              alt={selectedChild.firstName}
              className="w-20 h-20 rounded-full object-cover border-4 border-amber-400 shadow-md ring-4 ring-amber-100"
            />
            <span className="absolute bottom-0 right-0 w-6 h-6 bg-emerald-500 rounded-full border-2 border-white flex items-center justify-center text-white text-[10px] font-bold">
              ✓
            </span>
          </div>

          <h2 className="font-heading font-black text-xl text-slate-900 uppercase">
            {selectedChild.firstName} {selectedChild.lastName}
          </h2>
          <p className="text-xs text-amber-900 font-semibold mt-0.5">
            {selectedChild.groupName}
          </p>

          {/* QR Code */}
          <div className="my-4">
            <QrCodeDisplay
              value={selectedChild.qrCodeToken}
              size={170}
              label={selectedChild.qrCodeToken}
            />
          </div>

          <div className="w-full bg-amber-50 p-3 rounded-2xl border border-amber-200 text-left text-xs space-y-1">
            <div className="flex items-center gap-1.5 font-bold text-amber-950">
              <Phone className="w-3.5 h-3.5 text-amber-700" />
              <span>Contact d'urgence : {selectedChild.medicalInfo.emergencyContact}</span>
            </div>
            <p className="text-[11px] text-slate-600 pl-5">
              {selectedChild.medicalInfo.emergencyPhone}
            </p>
            {selectedChild.medicalInfo.allergies.length > 0 && (
              <p className="text-[11px] text-rose-700 font-bold pl-5">
                ⚠️ Allergies : {selectedChild.medicalInfo.allergies.join(', ')}
              </p>
            )}
          </div>

          <p className="text-[11px] text-slate-400 mt-4 leading-relaxed">
            Présentez ce QR Code au personnel de la crèche lors de la dépose du matin et de la reprise du soir pour un pointage instantané et sécurisé.
          </p>
        </div>
      </div>
    </div>
  );
};
