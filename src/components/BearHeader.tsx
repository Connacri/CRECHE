import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { useTranslation } from '../utils/i18n';
import { UserRole, Language } from '../types';
import {
  Bell,
  Search,
  Sparkles,
  ChevronDown,
  CheckCircle2,
  Users,
  School,
  GraduationCap,
  Truck,
  Package,
  Shield,
  Heart,
  QrCode,
  Plus,
} from 'lucide-react';

interface BearHeaderProps {
  onOpenNotifications: () => void;
  onOpenProfile: () => void;
  onOpenQrModal?: () => void;
  onOpenAddChildModal?: () => void;
}

const roleMeta: Record<UserRole, { label: string; icon: React.ReactNode; color: string; bg: string }> = {
  parent: { label: 'Espace Parent', icon: <Users className="w-4 h-4" />, color: 'text-amber-800', bg: 'bg-amber-100 border-amber-300' },
  school: { label: 'Direction / Crèche', icon: <School className="w-4 h-4" />, color: 'text-orange-800', bg: 'bg-orange-100 border-orange-300' },
  coach: { label: 'Coach & Animateur', icon: <GraduationCap className="w-4 h-4" />, color: 'text-emerald-800', bg: 'bg-emerald-100 border-emerald-300' },
  transporteur: { label: 'Logistique / Livraisons', icon: <Truck className="w-4 h-4" />, color: 'text-sky-800', bg: 'bg-sky-100 border-sky-300' },
  fournisseur: { label: 'Fournisseur Bio & Repas', icon: <Package className="w-4 h-4" />, color: 'text-purple-800', bg: 'bg-purple-100 border-purple-300' },
  admin: { label: 'Administration', icon: <Shield className="w-4 h-4" />, color: 'text-slate-800', bg: 'bg-slate-200 border-slate-300' },
  user: { label: 'Visiteur', icon: <Sparkles className="w-4 h-4" />, color: 'text-amber-800', bg: 'bg-amber-100 border-amber-200' },
  autres: { label: 'Partenaire', icon: <Sparkles className="w-4 h-4" />, color: 'text-teal-800', bg: 'bg-teal-100 border-teal-200' },
};

export const BearHeader: React.FC<BearHeaderProps> = ({
  onOpenNotifications,
  onOpenProfile,
  onOpenQrModal,
  onOpenAddChildModal,
}) => {
  const {
    currentUser,
    switchRole,
    language,
    setLanguage,
    unreadNotificationsCount,
    childrenList,
    selectedChildId,
    setSelectedChildId,
  } = useApp();

  const t = useTranslation(language);
  const [roleMenuOpen, setRoleMenuOpen] = useState(false);
  const [langMenuOpen, setLangMenuOpen] = useState(false);

  const currentRoleInfo = roleMeta[currentUser.role] || roleMeta.parent;
  const rolesList: UserRole[] = ['parent', 'school', 'coach', 'transporteur', 'fournisseur', 'admin'];

  const selectedChild = childrenList.find((c) => c.id === selectedChildId) || childrenList[0];

  return (
    <header className="sticky top-0 z-30 bg-[#FFB703] border-b border-amber-400 shadow-md transition-all">
      {/* Top Bear Bar */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-18">
          {/* Brand & Bear Mascot Motif */}
          <div className="flex items-center gap-3">
            <div className="relative group cursor-pointer" onClick={onOpenProfile}>
              <div className="w-12 h-12 rounded-2xl bg-white shadow-md flex items-center justify-center border-2 border-amber-200 transform hover:scale-105 transition">
                <span className="text-3xl leading-none select-none">🧸</span>
              </div>
              <span className="absolute -bottom-1 -right-1 w-4 h-4 bg-emerald-500 rounded-full border-2 border-white" />
            </div>

            <div>
              <div className="flex items-center gap-2">
                <span className="font-heading text-xl sm:text-2xl font-black tracking-wide text-slate-900 uppercase">
                  BEAR BABY
                </span>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-white/80 text-amber-900 border border-amber-300">
                  CRÈCHE
                </span>
              </div>
              <p className="text-xs text-amber-950 font-medium hidden sm:block">
                L'Avenir de la Petite Enfance & Suivi Quotidien
              </p>
            </div>
          </div>

          {/* Center search bar (desktop) */}
          <div className="hidden md:flex items-center flex-1 max-w-xs mx-6">
            <div className="relative w-full">
              <input
                type="text"
                placeholder="Rechercher activité, repas, fiche..."
                className="w-full pl-9 pr-4 py-2 rounded-full bg-white/90 border border-amber-300 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:bg-white transition shadow-xs"
              />
              <Search className="w-4 h-4 text-amber-700 absolute left-3 top-2.5" />
            </div>
          </div>

          {/* Right Action Icons: Role Switcher, Language, Notifications, Avatar */}
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Role Switcher Pill */}
            <div className="relative">
              <button
                onClick={() => {
                  setRoleMenuOpen(!roleMenuOpen);
                  setLangMenuOpen(false);
                }}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white text-slate-900 border border-amber-300 text-xs font-bold hover:bg-amber-50 shadow-xs transition"
              >
                <span className="text-amber-600">{currentRoleInfo.icon}</span>
                <span className="hidden sm:inline">{currentRoleInfo.label}</span>
                <ChevronDown className="w-3.5 h-3.5 text-slate-500" />
              </button>

              {roleMenuOpen && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setRoleMenuOpen(false)} />
                  <div className="absolute right-0 mt-2 w-64 bg-white rounded-3xl shadow-2xl border border-amber-200 p-2 z-50 animate-in fade-in slide-in-from-top-2 duration-150">
                    <div className="px-3 py-2 border-b border-amber-100">
                      <p className="text-[11px] font-black tracking-wider text-amber-600 uppercase">
                        {t.roleSelector}
                      </p>
                      <p className="text-xs text-slate-500">Choisissez votre espace métier :</p>
                    </div>
                    <div className="space-y-1 mt-1">
                      {rolesList.map((role) => {
                        const meta = roleMeta[role];
                        const isCurrent = currentUser.role === role;
                        return (
                          <button
                            key={role}
                            onClick={() => {
                              switchRole(role);
                              setRoleMenuOpen(false);
                            }}
                            className={`w-full flex items-center justify-between px-3 py-2 rounded-2xl text-left text-xs font-medium transition ${
                              isCurrent ? 'bg-amber-100 text-amber-950 font-bold' : 'hover:bg-amber-50 text-slate-700'
                            }`}
                          >
                            <div className="flex items-center gap-2.5">
                              <span className={`p-1.5 rounded-xl ${meta.bg} ${meta.color}`}>{meta.icon}</span>
                              <span>{meta.label}</span>
                            </div>
                            {isCurrent && <CheckCircle2 className="w-4 h-4 text-amber-600" />}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </>
              )}
            </div>

            {/* Language Pill */}
            <div className="relative">
              <button
                onClick={() => {
                  setLangMenuOpen(!langMenuOpen);
                  setRoleMenuOpen(false);
                }}
                className="w-8 h-8 rounded-full bg-white/90 hover:bg-white text-slate-800 flex items-center justify-center font-bold text-xs border border-amber-300 shadow-xs"
                title="Changer de langue"
              >
                {language.toUpperCase()}
              </button>
              {langMenuOpen && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setLangMenuOpen(false)} />
                  <div className="absolute right-0 mt-2 w-32 bg-white rounded-2xl shadow-xl border border-amber-200 p-1.5 z-50">
                    {[
                      { code: 'fr' as Language, label: 'Français', flag: '🇫🇷' },
                      { code: 'en' as Language, label: 'English', flag: '🇬🇧' },
                      { code: 'ar' as Language, label: 'العربية', flag: '🇩🇿' },
                    ].map((item) => (
                      <button
                        key={item.code}
                        onClick={() => {
                          setLanguage(item.code);
                          setLangMenuOpen(false);
                        }}
                        className={`w-full flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold ${
                          language === item.code ? 'bg-amber-100 text-amber-900' : 'hover:bg-slate-50 text-slate-700'
                        }`}
                      >
                        <span>{item.flag}</span>
                        <span>{item.label}</span>
                      </button>
                    ))}
                  </div>
                </>
              )}
            </div>

            {/* QR Code Quick Badge (Parent view) */}
            {currentUser.role === 'parent' && onOpenQrModal && (
              <button
                onClick={onOpenQrModal}
                className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-amber-50 hover:bg-white text-amber-950 font-bold text-xs border border-amber-300 shadow-xs transition"
                title="Badge QR Code de sécurité"
              >
                <QrCode className="w-3.5 h-3.5 text-amber-700" />
                <span>Badge QR</span>
              </button>
            )}

            {/* Notifications Bell with Unread Badge */}
            <button
              onClick={onOpenNotifications}
              className="relative w-9 h-9 rounded-full bg-white text-slate-800 hover:bg-amber-50 flex items-center justify-center border border-amber-300 shadow-xs transition"
              title="Notifications en direct"
            >
              <Bell className="w-4 h-4 text-amber-800" />
              {unreadNotificationsCount > 0 && (
                <span className="absolute -top-1 -right-1 w-5 h-5 bg-rose-500 text-white rounded-full text-[11px] font-black flex items-center justify-center border-2 border-white shadow-xs animate-bounce">
                  {unreadNotificationsCount}
                </span>
              )}
            </button>

            {/* User Profile Avatar */}
            <button
              onClick={onOpenProfile}
              className="flex items-center gap-2 p-1 rounded-full bg-white border border-amber-300 hover:ring-2 hover:ring-white transition"
              title="Mon Profil"
            >
              <img
                src={currentUser.avatarUrl || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'}
                alt={currentUser.fullName}
                className="w-7 h-7 rounded-full object-cover"
              />
            </button>
          </div>
        </div>

        {/* Sub-bar: Parent Child Switcher (Visible when Parent is logged in) */}
        {currentUser.role === 'parent' && (
          <div className="py-2.5 border-t border-amber-300/80 flex items-center justify-between gap-3 overflow-x-auto no-scrollbar">
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-amber-950 flex items-center gap-1">
                <Heart className="w-3.5 h-3.5 fill-rose-500 text-rose-500" /> Mes Enfants :
              </span>
              <div className="flex items-center gap-1.5">
                {childrenList.map((child) => {
                  const isSelected = child.id === selectedChild?.id;
                  const isCheckedIn = child.checkInStatus === 'checked_in';
                  return (
                    <button
                      key={child.id}
                      onClick={() => setSelectedChildId(child.id)}
                      className={`flex items-center gap-2 px-3 py-1 rounded-full text-xs font-bold transition shadow-xs ${
                        isSelected
                          ? 'bg-white text-slate-900 ring-2 ring-amber-600 scale-105'
                          : 'bg-amber-300/60 text-amber-950 hover:bg-white/80'
                      }`}
                    >
                      <img
                        src={child.photoUrl || 'https://images.unsplash.com/photo-1543332164-6e82f355badc?w=100'}
                        alt={child.firstName}
                        className="w-5 h-5 rounded-full object-cover"
                      />
                      <span>{child.firstName}</span>
                      <span
                        className={`w-2 h-2 rounded-full ${
                          isCheckedIn ? 'bg-emerald-500 animate-pulse' : 'bg-slate-400'
                        }`}
                        title={isCheckedIn ? 'À la crèche actuellement' : 'À la maison'}
                      />
                    </button>
                  );
                })}

                {onOpenAddChildModal && (
                  <button
                    onClick={onOpenAddChildModal}
                    className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/70 hover:bg-white text-amber-900 text-xs font-bold border border-dashed border-amber-400 transition"
                    title="Inscrire un autre enfant"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span className="hidden sm:inline">Ajouter</span>
                  </button>
                )}
              </div>
            </div>

            <div className="hidden lg:flex items-center gap-2 text-xs text-amber-950 font-semibold bg-white/60 px-3 py-1 rounded-full border border-amber-300">
              <span>Section : {selectedChild?.groupName || 'Petits Oursons'}</span>
              <span>•</span>
              <span className="text-emerald-700">
                {selectedChild?.checkInStatus === 'checked_in'
                  ? `🟢 Présent(e) depuis ${selectedChild.lastCheckInTime || '08h30'}`
                  : '⚪ Non enregistré(e)'}
              </span>
            </div>
          </div>
        )}
      </div>
    </header>
  );
};
