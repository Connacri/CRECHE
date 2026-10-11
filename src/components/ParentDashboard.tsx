import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { useTranslation } from '../utils/i18n';
import {
  Utensils,
  Moon,
  Baby,
  Thermometer,
  Camera,
  Heart,
  QrCode,
  ShieldCheck,
  Calendar,
  Sparkles,
  CheckCircle2,
  AlertTriangle,
  CreditCard,
  ChevronRight,
  BookOpen,
  Palette,
  Puzzle,
  MessageSquare,
  ArrowUpRight,
  Clock,
} from 'lucide-react';

interface ParentDashboardProps {
  onOpenNotifications: () => void;
  onOpenQrModal: () => void;
  onOpenFastLogger: () => void;
}

export const ParentDashboard: React.FC<ParentDashboardProps> = ({
  onOpenNotifications,
  onOpenQrModal,
  onOpenFastLogger,
}) => {
  const {
    selectedChild,
    getChildTransmission,
    togglePhotoLike,
    setParentMorningNote,
    courses,
    enrollChild,
    invoices,
    payInvoice,
    language,
    toggleCheckInStatus,
  } = useApp();

  const t = useTranslation(language);
  const [morningNoteInput, setMorningNoteInput] = useState('');
  const [isEditingNote, setIsEditingNote] = useState(false);
  const [activeCategoryFilter, setActiveCategoryFilter] = useState<string>('all');

  if (!selectedChild) return null;

  const transmission = getChildTransmission(selectedChild.id);
  const isCheckedIn = selectedChild.checkInStatus === 'checked_in';

  const handleSaveMorningNote = (e: React.FormEvent) => {
    e.preventDefault();
    if (morningNoteInput.trim()) {
      setParentMorningNote(selectedChild.id, morningNoteInput.trim());
      setIsEditingNote(false);
      setMorningNoteInput('');
    }
  };

  const getEatenBadge = (qty: string) => {
    switch (qty) {
      case 'all':
        return { label: 'Tout mangé (100%)', bg: 'bg-emerald-100 text-emerald-800 border-emerald-300', emoji: '🟢' };
      case 'good':
        return { label: 'Bien mangé (75%)', bg: 'bg-amber-100 text-amber-800 border-amber-300', emoji: '🟡' };
      case 'little':
        return { label: 'Un peu mangé (25%)', bg: 'bg-orange-100 text-orange-800 border-orange-300', emoji: '🟠' };
      default:
        return { label: 'Refusé / Rien mangé', bg: 'bg-rose-100 text-rose-800 border-rose-300', emoji: '🔴' };
    }
  };

  const unpaidInvoices = invoices.filter((i) => i.status !== 'paid');
  const totalDue = unpaidInvoices.reduce((acc, i) => acc + i.amount, 0);

  return (
    <div className="space-y-6 pb-20">
      {/* 1. Hero Feature Banner (Inspired by BEAR BABY uploaded card) */}
      <div className="relative rounded-3xl overflow-hidden bg-gradient-to-br from-[#FFB703] via-[#FFA200] to-[#FB8500] p-6 sm:p-8 text-slate-900 shadow-xl border border-amber-300">
        {/* Background decorative elements */}
        <div className="absolute -right-6 -bottom-8 w-44 h-44 sm:w-56 sm:h-56 bg-white/20 rounded-full blur-xl pointer-events-none" />
        <div className="absolute right-4 top-4 text-7xl sm:text-8xl select-none opacity-90 transform hover:scale-110 transition duration-300">
          🧸
        </div>

        <div className="relative z-10 max-w-lg">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/80 backdrop-blur-xs text-xs font-black text-amber-950 uppercase tracking-wider mb-3 shadow-xs">
            <Sparkles className="w-3.5 h-3.5 text-amber-600" />
            <span>JOURNÉE DE {selectedChild.firstName.toUpperCase()}</span>
          </div>

          <h1 className="font-heading text-2xl sm:text-4xl font-black uppercase tracking-tight text-slate-900 leading-tight">
            LOVE TO PLAY FROM HERE
          </h1>
          <p className="text-xs sm:text-sm font-semibold text-amber-950 mt-1 max-w-md">
            Suivi en temps réel des repas, siestes, soins et activités de votre enfant à la crèche.
          </p>

          {/* Quick status row */}
          <div className="flex flex-wrap items-center gap-3 mt-4">
            <div
              className={`px-3 py-1.5 rounded-full text-xs font-black flex items-center gap-1.5 shadow-xs ${
                isCheckedIn
                  ? 'bg-emerald-500 text-white'
                  : 'bg-white/90 text-slate-800'
              }`}
            >
              <span className="w-2.5 h-2.5 rounded-full bg-white animate-pulse" />
              <span>
                {isCheckedIn
                  ? `À la crèche (depuis ${selectedChild.lastCheckInTime || '08h30'})`
                  : 'À la maison / Non pointé'}
              </span>
            </div>

            <button
              onClick={onOpenQrModal}
              className="px-3.5 py-1.5 rounded-full bg-white hover:bg-amber-50 text-slate-900 font-bold text-xs flex items-center gap-1.5 shadow-xs border border-amber-300 transition"
            >
              <QrCode className="w-3.5 h-3.5 text-amber-700" />
              <span>Badge Sécurité QR</span>
            </button>

            <button
              onClick={() =>
                toggleCheckInStatus(
                  selectedChild.id,
                  isCheckedIn ? 'picked_up' : 'checked_in'
                )
              }
              className="px-3 py-1.5 rounded-full bg-amber-900/15 hover:bg-amber-900/25 text-amber-950 font-bold text-xs transition"
            >
              {isCheckedIn ? 'Simuler départ (Récupéré)' : 'Simuler arrivée (Pointage)'}
            </button>
          </div>
        </div>
      </div>

      {/* 2. Toy / Nursery Category Shortcut Buttons (ABC, Puzzle, Painting, Parent-Child) */}
      <div className="grid grid-cols-4 gap-2.5 sm:gap-4">
        {[
          { label: 'ABC Éveil', sub: 'Jeux & Langage', icon: <BookOpen className="w-5 h-5 text-amber-600" />, bg: 'bg-amber-50 border-amber-200 hover:bg-amber-100/60' },
          { label: 'Motricité', sub: 'Baby Gym', icon: <Puzzle className="w-5 h-5 text-emerald-600" />, bg: 'bg-emerald-50 border-emerald-200 hover:bg-emerald-100/60' },
          { label: 'Peinture', sub: 'Arts & Couleurs', icon: <Palette className="w-5 h-5 text-rose-600" />, bg: 'bg-rose-50 border-rose-200 hover:bg-rose-100/60' },
          { label: 'Liaison', sub: 'Suivi & Repas', icon: <Heart className="w-5 h-5 text-indigo-600" />, bg: 'bg-indigo-50 border-indigo-200 hover:bg-indigo-100/60' },
        ].map((item, idx) => (
          <div
            key={idx}
            className={`p-3 sm:p-4 rounded-3xl border transition cursor-pointer text-center flex flex-col items-center justify-center gap-1 shadow-xs ${item.bg}`}
          >
            <div className="w-10 h-10 rounded-2xl bg-white shadow-xs flex items-center justify-center mb-0.5">
              {item.icon}
            </div>
            <span className="font-heading font-black text-xs sm:text-sm text-slate-800 uppercase">
              {item.label}
            </span>
            <span className="text-[10px] text-slate-500 font-medium hidden sm:inline">
              {item.sub}
            </span>
          </div>
        ))}
      </div>

      {/* 3. Live Transmissions Today: Meals, Naps, Diapers, Health */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column (2 Cols): Live Day Transmission Cards */}
        <div className="lg:col-span-2 space-y-6">
          {/* A. REPAS & ALIMENTATION DU JOUR */}
          <div className="bg-white rounded-3xl p-5 sm:p-6 border border-amber-200 shadow-md">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-700 flex items-center justify-center text-xl shadow-xs">
                  🥣
                </div>
                <div>
                  <h3 className="font-heading font-black text-base text-slate-900 uppercase">
                    SUIVI DES REPAS & NUTRITION
                  </h3>
                  <p className="text-xs text-slate-500 font-medium">
                    Menu du jour bio & portions mangées
                  </p>
                </div>
              </div>
              <button
                onClick={onOpenFastLogger}
                className="text-xs font-bold text-amber-700 hover:text-amber-800 bg-amber-50 hover:bg-amber-100 px-3 py-1.5 rounded-full border border-amber-200 transition"
              >
                + Ajouter repas
              </button>
            </div>

            {transmission.meals.length === 0 ? (
              <p className="text-xs text-slate-500 py-3 text-center">
                Aucun repas enregistré pour l'instant aujourd'hui.
              </p>
            ) : (
              <div className="space-y-3">
                {transmission.meals.map((meal) => {
                  const badge = getEatenBadge(meal.quantity);
                  return (
                    <div
                      key={meal.id}
                      className="p-3.5 rounded-2xl bg-amber-50/50 border border-amber-200 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
                    >
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 rounded-xl bg-white border border-amber-200 flex items-center justify-center text-base shrink-0 shadow-xs">
                          {meal.mealType === 'bottle' ? '🍼' : '🍽️'}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-bold text-xs text-slate-900">{meal.title}</span>
                            <span className="text-[10px] text-slate-400 font-mono">({meal.time})</span>
                          </div>
                          <p className="text-xs text-slate-600 mt-0.5">{meal.menuDescription}</p>
                          {meal.notes && (
                            <p className="text-[11px] text-amber-800 font-medium mt-1 italic">
                              « {meal.notes} »
                            </p>
                          )}
                        </div>
                      </div>

                      <div className="shrink-0 flex items-center gap-2 self-end sm:self-center">
                        <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold border flex items-center gap-1 ${badge.bg}`}>
                          <span>{badge.emoji}</span>
                          <span>{badge.label}</span>
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* B. SOMMEIL & SIESTE */}
          <div className="bg-white rounded-3xl p-5 sm:p-6 border border-indigo-200 shadow-md">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-2xl bg-indigo-100 text-indigo-700 flex items-center justify-center text-xl shadow-xs">
                  💤
                </div>
                <div>
                  <h3 className="font-heading font-black text-base text-slate-900 uppercase">
                    TEMPS DE SIESTE & REPOS
                  </h3>
                  <p className="text-xs text-slate-500 font-medium">
                    Heure d'endormissement et qualité du dodo
                  </p>
                </div>
              </div>
              <button
                onClick={onOpenFastLogger}
                className="text-xs font-bold text-indigo-700 hover:text-indigo-800 bg-indigo-50 hover:bg-indigo-100 px-3 py-1.5 rounded-full border border-indigo-200 transition"
              >
                + Noter sieste
              </button>
            </div>

            {transmission.naps.length === 0 ? (
              <p className="text-xs text-slate-500 py-3 text-center">
                Pas de sieste enregistrée aujourd'hui.
              </p>
            ) : (
              <div className="space-y-3">
                {transmission.naps.map((nap) => (
                  <div
                    key={nap.id}
                    className={`p-3.5 rounded-2xl border flex items-center justify-between gap-3 ${
                      nap.isSleeping
                        ? 'bg-indigo-50/70 border-indigo-300 ring-1 ring-indigo-300'
                        : 'bg-slate-50 border-slate-200'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-white border border-indigo-200 flex items-center justify-center text-lg shadow-xs">
                        {nap.isSleeping ? '😴' : '☀️'}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-xs text-slate-900">
                            {nap.isSleeping ? 'Dodo en cours...' : 'Sieste terminée'}
                          </span>
                          {nap.isSleeping && (
                            <span className="px-2 py-0.5 rounded-full bg-indigo-500 text-white text-[10px] font-bold animate-pulse">
                              En train de dormir
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-slate-500 mt-0.5">
                          Début : {nap.startTime}
                          {nap.endTime ? ` • Réveil : ${nap.endTime} (${nap.durationMinutes} min)` : ''}
                        </p>
                        {nap.notes && (
                          <p className="text-[11px] text-slate-600 mt-1 italic">« {nap.notes} »</p>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* C. CHANGES & HYGIÈNE + SANTÉ */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {/* Diapers Card */}
            <div className="bg-white rounded-3xl p-5 border border-sky-200 shadow-md">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-sky-100 text-sky-700 flex items-center justify-center text-base">
                    🧷
                  </div>
                  <h4 className="font-heading font-black text-sm text-slate-900 uppercase">
                    CHANGES & SOINS
                  </h4>
                </div>
                <button
                  onClick={onOpenFastLogger}
                  className="text-[11px] font-bold text-sky-700 bg-sky-50 px-2.5 py-1 rounded-full"
                >
                  + Change
                </button>
              </div>

              {transmission.diapers.length === 0 ? (
                <p className="text-xs text-slate-400 py-2">Aucun change renseigné.</p>
              ) : (
                <div className="space-y-2">
                  {transmission.diapers.map((d) => (
                    <div
                      key={d.id}
                      className={`p-2.5 rounded-xl border text-xs flex items-center justify-between ${
                        d.needsRefillAlert
                          ? 'bg-amber-50 border-amber-300'
                          : 'bg-sky-50/50 border-sky-100'
                      }`}
                    >
                      <div>
                        <span className="font-bold text-slate-800">
                          {d.time} • {d.type === 'clean' ? '✨ Propre' : d.type === 'stool' ? '💩 Selles' : '💧 Pipi'}
                        </span>
                        {d.careApplied && (
                          <p className="text-[11px] text-slate-500 mt-0.5">{d.careApplied}</p>
                        )}
                      </div>
                      {d.needsRefillAlert && (
                        <span className="px-2 py-0.5 rounded-full bg-amber-500 text-white text-[10px] font-black uppercase">
                          Rappel Couches !
                        </span>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Health & Fever Card */}
            <div className="bg-white rounded-3xl p-5 border border-rose-200 shadow-md">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-rose-100 text-rose-700 flex items-center justify-center text-base">
                    🌡️
                  </div>
                  <h4 className="font-heading font-black text-sm text-slate-900 uppercase">
                    TEMPÉRATURE & SANTÉ
                  </h4>
                </div>
                <button
                  onClick={onOpenFastLogger}
                  className="text-[11px] font-bold text-rose-700 bg-rose-50 px-2.5 py-1 rounded-full"
                >
                  + Contrôle
                </button>
              </div>

              {transmission.health.length === 0 ? (
                <p className="text-xs text-slate-400 py-2">Aucune mesure de température.</p>
              ) : (
                <div className="space-y-2">
                  {transmission.health.map((h) => (
                    <div
                      key={h.id}
                      className={`p-2.5 rounded-xl border text-xs flex items-center justify-between ${
                        h.isFever
                          ? 'bg-rose-50 border-rose-300 text-rose-900 animate-pulse'
                          : 'bg-emerald-50/60 border-emerald-200 text-slate-800'
                      }`}
                    >
                      <div>
                        <div className="flex items-center gap-1.5 font-bold">
                          <span>{h.time}</span>
                          <span>•</span>
                          <span className="text-sm font-black">{h.temperature}°C</span>
                        </div>
                        {h.actionTaken && (
                          <p className="text-[11px] text-slate-600 mt-0.5">{h.actionTaken}</p>
                        )}
                      </div>
                      <span
                        className={`px-2 py-0.5 rounded-full text-[10px] font-black uppercase ${
                          h.isFever ? 'bg-rose-600 text-white' : 'bg-emerald-100 text-emerald-800'
                        }`}
                      >
                        {h.isFever ? 'Fièvre 🚨' : 'Normal ✅'}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* D. GALERIE PHOTOS DU JOUR (Moments Doux) */}
          <div className="bg-white rounded-3xl p-5 sm:p-6 border border-amber-200 shadow-md">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <div className="w-9 h-9 rounded-2xl bg-amber-100 text-amber-700 flex items-center justify-center text-lg">
                  📸
                </div>
                <div>
                  <h3 className="font-heading font-black text-base text-slate-900 uppercase">
                    PHOTOS & MOMENTS DU JOUR
                  </h3>
                  <p className="text-xs text-slate-500 font-medium">
                    Partagés avec amour par l'équipe des Petits Oursons
                  </p>
                </div>
              </div>
              <button
                onClick={onOpenFastLogger}
                className="text-xs font-bold text-amber-800 bg-amber-50 px-3 py-1.5 rounded-full border border-amber-200"
              >
                + Ajouter photo
              </button>
            </div>

            {transmission.photos.length === 0 ? (
              <p className="text-xs text-slate-400 py-3 text-center">
                Les photos de l'atelier de la journée apparaîtront ici dès publication.
              </p>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {transmission.photos.map((photo) => (
                  <div
                    key={photo.id}
                    className="rounded-2xl border border-amber-200 overflow-hidden bg-amber-50/30 shadow-xs flex flex-col"
                  >
                    <div className="relative h-48 bg-slate-100 overflow-hidden group">
                      <img
                        src={photo.url}
                        alt="Moment"
                        className="w-full h-full object-cover group-hover:scale-105 transition duration-300"
                      />
                      <button
                        onClick={() => togglePhotoLike(selectedChild.id, photo.id)}
                        className={`absolute top-3 right-3 px-3 py-1.5 rounded-full flex items-center gap-1.5 text-xs font-bold backdrop-blur-md transition shadow-md ${
                          photo.hasLiked
                            ? 'bg-rose-500 text-white'
                            : 'bg-white/90 text-slate-700 hover:bg-white'
                        }`}
                      >
                        <Heart className={`w-3.5 h-3.5 ${photo.hasLiked ? 'fill-white' : ''}`} />
                        <span>{photo.likes}</span>
                      </button>
                    </div>
                    <div className="p-3 flex-1 flex flex-col justify-between">
                      <p className="text-xs font-medium text-slate-800 leading-relaxed">
                        {photo.caption}
                      </p>
                      <div className="flex items-center justify-between text-[10px] text-slate-400 mt-2 font-medium">
                        <span>Heure : {photo.time}</span>
                        <span className="text-amber-800 font-bold">Crèche Les Petits Oursons</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Column: Cahier de liaison, Factures, Cours, Alertes */}
        <div className="space-y-6">
          {/* Cahier de liaison & Mot du Matin des Parents */}
          <div className="bg-white rounded-3xl p-5 border border-amber-200 shadow-md">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-8 h-8 rounded-xl bg-amber-100 text-amber-800 flex items-center justify-center text-sm font-bold">
                📝
              </div>
              <div>
                <h4 className="font-heading font-black text-sm text-slate-900 uppercase">
                  MOT DU MATIN (PARENT)
                </h4>
                <p className="text-[11px] text-slate-500">Transmettre une consigne à l'équipe</p>
              </div>
            </div>

            {transmission.parentMorningNote ? (
              <div className="p-3 rounded-2xl bg-amber-50/70 border border-amber-200 text-xs text-slate-800 italic relative">
                « {transmission.parentMorningNote} »
                <button
                  onClick={() => {
                    setMorningNoteInput(transmission.parentMorningNote || '');
                    setIsEditingNote(true);
                  }}
                  className="block text-[11px] font-bold text-amber-800 mt-2 underline"
                >
                  Modifier mon mot
                </button>
              </div>
            ) : (
              <p className="text-xs text-slate-400 mb-2">Aucun mot laissé ce matin.</p>
            )}

            {(!transmission.parentMorningNote || isEditingNote) && (
              <form onSubmit={handleSaveMorningNote} className="mt-3 space-y-2">
                <textarea
                  rows={2}
                  value={morningNoteInput}
                  onChange={(e) => setMorningNoteInput(e.target.value)}
                  placeholder="Ex: A mal dormi, poussée dentaire, besoin de câlins supplémentaires..."
                  className="w-full p-2.5 rounded-xl border border-amber-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
                />
                <div className="flex gap-2">
                  <button
                    type="submit"
                    className="flex-1 py-1.5 rounded-xl bg-amber-500 text-white font-bold text-xs hover:bg-amber-600 transition"
                  >
                    Transmettre à l'équipe
                  </button>
                  {isEditingNote && (
                    <button
                      type="button"
                      onClick={() => setIsEditingNote(false)}
                      className="px-3 py-1.5 rounded-xl bg-slate-100 text-slate-600 font-bold text-xs"
                    >
                      Annuler
                    </button>
                  )}
                </div>
              </form>
            )}

            {/* Note retour du soir des éducatrices */}
            {transmission.staffNotes && (
              <div className="mt-4 pt-4 border-t border-amber-100">
                <span className="text-[11px] font-black uppercase text-amber-900 block mb-1">
                  Transmissions du soir (Éducatrice) :
                </span>
                <p className="text-xs text-slate-700 bg-slate-50 p-3 rounded-2xl border border-slate-200">
                  {transmission.staffNotes}
                </p>
              </div>
            )}
          </div>

          {/* Wallet / Facturation Card */}
          <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-3xl p-5 border border-amber-200 shadow-md">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-white shadow-xs text-amber-700 flex items-center justify-center">
                  <CreditCard className="w-4 h-4" />
                </div>
                <h4 className="font-heading font-black text-sm text-slate-900 uppercase">
                  FACTURES & PORTAL
                </h4>
              </div>
              <span className="text-xs font-bold text-slate-500">Mois en cours</span>
            </div>

            <div className="flex items-baseline justify-between mb-3">
              <span className="text-xs font-semibold text-slate-600">Reste à régler :</span>
              <span className="text-2xl font-heading font-black text-slate-900">
                {totalDue > 0 ? `${totalDue} €` : '0 € (À jour 🎉)'}
              </span>
            </div>

            {unpaidInvoices.length > 0 ? (
              <div className="space-y-2 mb-3">
                {unpaidInvoices.map((inv) => (
                  <div
                    key={inv.id}
                    className="p-2.5 rounded-xl bg-white border border-amber-200 flex items-center justify-between text-xs"
                  >
                    <div>
                      <p className="font-bold text-slate-800">{inv.courseTitle}</p>
                      <p className="text-[10px] text-slate-400">Échéance : {inv.dueDate}</p>
                    </div>
                    <button
                      onClick={() => payInvoice(inv.id)}
                      className="px-3 py-1 rounded-full bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs shadow-xs transition"
                    >
                      Payer {inv.amount} €
                    </button>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-emerald-700 bg-emerald-50 p-2 rounded-xl mb-3 font-semibold">
                Toutes vos factures crèche et activités sont réglées.
              </p>
            )}
          </div>

          {/* Cours & Activités Périscolaires */}
          <div className="bg-white rounded-3xl p-5 border border-amber-200 shadow-md">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center text-sm font-bold">
                  🧩
                </div>
                <h4 className="font-heading font-black text-sm text-slate-900 uppercase">
                  COURS & ATELIERS
                </h4>
              </div>
              <span className="text-xs font-bold text-amber-800">Catalogue</span>
            </div>

            <div className="space-y-3">
              {courses.slice(0, 3).map((c) => (
                <div
                  key={c.id}
                  className="p-3 rounded-2xl border border-slate-200 hover:border-amber-400 transition bg-slate-50/50 flex items-center justify-between gap-2"
                >
                  <div>
                    <h5 className="font-bold text-xs text-slate-900">{c.title}</h5>
                    <p className="text-[10px] text-slate-500">
                      {c.scheduleDays.join(', ')} • {c.startTime} - {c.endTime}
                    </p>
                    <span className="text-xs font-bold text-amber-800 mt-1 inline-block">
                      {c.price} € / mois
                    </span>
                  </div>
                  <button
                    onClick={() => enrollChild(c.id, selectedChild.id)}
                    className="px-3 py-1.5 rounded-full bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold shrink-0 transition shadow-xs"
                  >
                    Inscrire
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
