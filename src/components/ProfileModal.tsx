import React from 'react';
import { useApp } from '../context/AppContext';
import { UserRole, Language } from '../types';
import { X, User, Phone, MapPin, Mail, Shield, CheckCircle2, Globe, LogOut } from 'lucide-react';

interface ProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const ProfileModal: React.FC<ProfileModalProps> = ({ isOpen, onClose }) => {
  const { currentUser, switchRole, language, setLanguage } = useApp();

  if (!isOpen) return null;

  const rolesList: { role: UserRole; label: string; desc: string }[] = [
    { role: 'parent', label: 'Espace Parent', desc: 'Suivi des enfants, repas, siestes et factures' },
    { role: 'school', label: 'Direction & Crèche', desc: 'Pointage, transmissions d’équipe, cours et planning' },
    { role: 'coach', label: 'Coach & Animateur', desc: 'Gestion des séances sport & ateliers' },
    { role: 'transporteur', label: 'Transporteur', desc: 'Logistique et livraisons repas / couches' },
    { role: 'fournisseur', label: 'Fournisseur', desc: 'Commandes repas bio & puériculture' },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-150">
      <div className="relative w-full max-w-md bg-white rounded-3xl shadow-2xl border border-amber-300 overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="p-4 sm:p-5 bg-gradient-to-r from-amber-400 to-[#FFB703] border-b border-amber-300 flex items-center justify-between text-slate-900">
          <div className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-2xl bg-white flex items-center justify-center text-xl shadow-xs">
              👤
            </div>
            <div>
              <h2 className="font-heading font-black text-lg tracking-wide uppercase">
                PROFIL & PARAMÈTRES
              </h2>
              <p className="text-xs text-amber-950 font-medium">Gestion du compte et rôles</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/80 hover:bg-white text-slate-800 flex items-center justify-center transition shadow-xs"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5 overflow-y-auto space-y-5 text-xs bg-[#FFFDF7]">
          {/* User Card */}
          <div className="p-4 rounded-3xl bg-white border border-amber-200 shadow-sm flex items-center gap-3.5">
            <img
              src={currentUser.avatarUrl || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'}
              alt={currentUser.fullName}
              className="w-14 h-14 rounded-2xl object-cover border-2 border-amber-400"
            />
            <div>
              <h3 className="font-bold text-sm text-slate-900">{currentUser.fullName}</h3>
              <p className="text-slate-500">{currentUser.email}</p>
              <span className="inline-block px-2.5 py-0.5 rounded-full bg-amber-100 text-amber-800 text-[10px] font-bold uppercase mt-1">
                Rôle actuel : {currentUser.role}
              </span>
            </div>
          </div>

          {/* Switch Role Selection */}
          <div>
            <h4 className="font-heading font-black text-xs uppercase text-amber-900 mb-2">
              Changer d'espace métier :
            </h4>
            <div className="space-y-2">
              {rolesList.map((item) => {
                const isSelected = currentUser.role === item.role;
                return (
                  <button
                    key={item.role}
                    onClick={() => switchRole(item.role)}
                    className={`w-full p-3 rounded-2xl border text-left transition flex items-center justify-between ${
                      isSelected
                        ? 'bg-amber-100 border-amber-500 shadow-xs ring-1 ring-amber-400'
                        : 'bg-white border-slate-200 hover:bg-amber-50/60'
                    }`}
                  >
                    <div>
                      <strong className="text-xs text-slate-900 block">{item.label}</strong>
                      <span className="text-[11px] text-slate-500">{item.desc}</span>
                    </div>
                    {isSelected && <CheckCircle2 className="w-4 h-4 text-amber-600 shrink-0" />}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Language selector */}
          <div className="pt-3 border-t border-amber-100">
            <h4 className="font-heading font-black text-xs uppercase text-amber-900 mb-2">
              Langue de l'application :
            </h4>
            <div className="grid grid-cols-3 gap-2">
              {[
                { code: 'fr' as Language, label: 'Français', flag: '🇫🇷' },
                { code: 'en' as Language, label: 'English', flag: '🇬🇧' },
                { code: 'ar' as Language, label: 'العربية', flag: '🇩🇿' },
              ].map((l) => (
                <button
                  key={l.code}
                  onClick={() => setLanguage(l.code)}
                  className={`py-2 rounded-xl text-xs font-bold border transition ${
                    language === l.code
                      ? 'bg-amber-500 text-white border-amber-600'
                      : 'bg-white border-slate-200 hover:bg-slate-50 text-slate-700'
                  }`}
                >
                  {l.flag} {l.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
