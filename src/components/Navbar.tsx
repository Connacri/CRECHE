import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { useTranslation } from '../utils/i18n';
import { UserRole, Language } from '../types';
import {
  Users,
  School,
  GraduationCap,
  Truck,
  Package,
  Shield,
  Globe,
  ChevronDown,
  UserCheck,
  CheckCircle2,
  Sparkles,
} from 'lucide-react';

const roleMeta: Record<UserRole, { label: string; icon: React.ReactNode; color: string; bg: string }> = {
  parent: { label: 'Espace Parent', icon: <Users className="w-4 h-4" />, color: 'text-rose-600', bg: 'bg-rose-50 border-rose-200' },
  school: { label: 'Direction / Crèche', icon: <School className="w-4 h-4" />, color: 'text-indigo-600', bg: 'bg-indigo-50 border-indigo-200' },
  coach: { label: 'Coach & Animateur', icon: <GraduationCap className="w-4 h-4" />, color: 'text-emerald-600', bg: 'bg-emerald-50 border-emerald-200' },
  transporteur: { label: 'Transport & Logistique', icon: <Truck className="w-4 h-4" />, color: 'text-amber-600', bg: 'bg-amber-50 border-amber-200' },
  fournisseur: { label: 'Fournisseur / Repas', icon: <Package className="w-4 h-4" />, color: 'text-purple-600', bg: 'bg-purple-50 border-purple-200' },
  admin: { label: 'Administration', icon: <Shield className="w-4 h-4" />, color: 'text-slate-700', bg: 'bg-slate-100 border-slate-300' },
  user: { label: 'Visiteur', icon: <UserCheck className="w-4 h-4" />, color: 'text-sky-600', bg: 'bg-sky-50 border-sky-200' },
  autres: { label: 'Partenaire', icon: <Sparkles className="w-4 h-4" />, color: 'text-teal-600', bg: 'bg-teal-50 border-teal-200' },
};

export const Navbar: React.FC<{ onOpenProfile: () => void }> = ({ onOpenProfile }) => {
  const { currentUser, switchRole, language, setLanguage } = useApp();
  const t = useTranslation(language);
  const [roleMenuOpen, setRoleMenuOpen] = useState(false);
  const [langMenuOpen, setLangMenuOpen] = useState(false);

  const currentMeta = roleMeta[currentUser.role] || roleMeta.parent;

  const rolesList: UserRole[] = ['parent', 'school', 'coach', 'transporteur', 'fournisseur', 'admin'];

  return (
    <header className="sticky top-0 z-40 bg-white/90 backdrop-blur-md border-b border-slate-200 shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Brand Logo & Name */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-amber-400 via-rose-400 to-indigo-500 flex items-center justify-center text-white shadow-md shadow-rose-500/20 text-xl font-bold">
              🧸
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-lg font-bold tracking-tight text-slate-900">Crèche & Club</span>
                <span className="text-xs px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 font-semibold border border-amber-200">
                  v1.2
                </span>
              </div>
              <p className="text-xs text-slate-500 hidden sm:block">L'Avenir de la Petite Enfance & Activités</p>
            </div>
          </div>

          {/* Right Controls: Role Switcher, Language, Profile */}
          <div className="flex items-center gap-2 sm:gap-4">
            {/* Quick Role Selector Dropdown */}
            <div className="relative">
              <button
                onClick={() => {
                  setRoleMenuOpen(!roleMenuOpen);
                  setLangMenuOpen(false);
                }}
                className={`flex items-center gap-2 px-3 py-1.5 rounded-xl border text-xs sm:text-sm font-medium transition-all shadow-xs ${currentMeta.bg}`}
              >
                <span className={currentMeta.color}>{currentMeta.icon}</span>
                <span className="font-semibold text-slate-800">{currentMeta.label}</span>
                <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
              </button>

              {roleMenuOpen && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setRoleMenuOpen(false)} />
                  <div className="absolute right-0 mt-2 w-64 bg-white rounded-2xl shadow-2xl border border-slate-100 p-2 z-50 animate-in fade-in slide-in-from-top-2 duration-150">
                    <div className="px-3 py-2 border-b border-slate-100">
                      <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                        {t.roleSelector}
                      </p>
                      <p className="text-xs text-slate-500">Basculez entre les espaces métiers</p>
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
                            className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-left text-sm transition-colors ${
                              isCurrent ? 'bg-indigo-50 text-indigo-900 font-semibold' : 'hover:bg-slate-50 text-slate-700'
                            }`}
                          >
                            <div className="flex items-center gap-2.5">
                              <span className={`p-1.5 rounded-lg ${meta.bg} ${meta.color}`}>{meta.icon}</span>
                              <span>{meta.label}</span>
                            </div>
                            {isCurrent && <CheckCircle2 className="w-4 h-4 text-indigo-600" />}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </>
              )}
            </div>

            {/* Language Switcher */}
            <div className="relative">
              <button
                onClick={() => {
                  setLangMenuOpen(!langMenuOpen);
                  setRoleMenuOpen(false);
                }}
                className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-xs font-medium text-slate-700 transition shadow-xs"
                title="Langue / Language"
              >
                <Globe className="w-3.5 h-3.5 text-slate-500" />
                <span className="uppercase font-bold">{language}</span>
              </button>

              {langMenuOpen && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setLangMenuOpen(false)} />
                  <div className="absolute right-0 mt-2 w-36 bg-white rounded-2xl shadow-xl border border-slate-100 p-1.5 z-50">
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
                        className={`w-full flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-medium ${
                          language === item.code ? 'bg-indigo-50 text-indigo-700 font-bold' : 'hover:bg-slate-50 text-slate-700'
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

            {/* User Avatar & Profile Quick Tap */}
            <button
              onClick={onOpenProfile}
              className="flex items-center gap-2 p-1 pl-2 pr-3 rounded-full hover:bg-slate-100 border border-slate-200 transition shadow-xs"
            >
              <img
                src={currentUser.avatarUrl || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'}
                alt={currentUser.fullName}
                className="w-7 h-7 rounded-full object-cover ring-2 ring-indigo-500/20"
              />
              <span className="text-xs font-semibold text-slate-800 max-w-[100px] truncate hidden md:inline">
                {currentUser.fullName}
              </span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};
