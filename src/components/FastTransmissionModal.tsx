import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Child, EatenQuantity, ChildMood } from '../types';
import {
  X,
  Utensils,
  Moon,
  Baby,
  Thermometer,
  Camera,
  CheckCircle2,
  AlertCircle,
  Clock,
  Sparkles,
} from 'lucide-react';

interface FastTransmissionModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultChildId?: string;
}

export const FastTransmissionModal: React.FC<FastTransmissionModalProps> = ({
  isOpen,
  onClose,
  defaultChildId,
}) => {
  const {
    childrenList,
    logMeal,
    logNap,
    logDiaper,
    logHealth,
    addMomentPhoto,
    setChildMood,
  } = useApp();

  const [selectedChildId, setSelectedChildId] = useState<string>(
    defaultChildId || childrenList[0]?.id || ''
  );

  const [activeTab, setActiveTab] = useState<'meal' | 'nap' | 'diaper' | 'health' | 'photo' | 'mood'>('meal');
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Meal form state
  const [mealType, setMealType] = useState<'lunch' | 'snack' | 'bottle' | 'breakfast'>('lunch');
  const [menuDescription, setMenuDescription] = useState('Purée de légumes bio et compote de pommes');
  const [eatenQuantity, setEatenQuantity] = useState<EatenQuantity>('all');
  const [bottleDrankMl, setBottleDrankMl] = useState<number>(210);

  // Nap form state
  const [napAction, setNapAction] = useState<'sleep_start' | 'wake_up'>('sleep_start');
  const [napQuality, setNapQuality] = useState<'calm' | 'normal' | 'agitated'>('calm');
  const [napDurationMinutes, setNapDurationMinutes] = useState(90);

  // Diaper form state
  const [diaperType, setDiaperType] = useState<'clean' | 'wet' | 'stool' | 'both'>('wet');
  const [careApplied, setCareApplied] = useState('Change doux habituel');
  const [needsRefillAlert, setNeedsRefillAlert] = useState(false);

  // Health form state
  const [temperature, setTemperature] = useState<number>(37.0);
  const [healthAction, setHealthAction] = useState('');

  // Photo form state
  const [photoCaption, setPhotoCaption] = useState('Grand sourire pendant l’activité manuelle !');
  const [photoUrl, setPhotoUrl] = useState(
    'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80'
  );

  if (!isOpen) return null;

  const currentChild = childrenList.find((c) => c.id === selectedChildId) || childrenList[0];
  const nowTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  const showSuccess = (msg: string) => {
    setSuccessMessage(msg);
    setTimeout(() => {
      setSuccessMessage(null);
      onClose();
    }, 1500);
  };

  const handleSaveMeal = () => {
    if (!currentChild) return;
    const title = mealType === 'lunch' ? 'Déjeuner' : mealType === 'snack' ? 'Goûter' : mealType === 'bottle' ? 'Biberon' : 'Petit-déjeuner';
    logMeal(currentChild.id, {
      time: nowTime,
      mealType,
      title,
      menuDescription: mealType === 'bottle' ? `Biberon ${bottleDrankMl} ml bus` : menuDescription,
      quantity: eatenQuantity,
      bottleDrankMl: mealType === 'bottle' ? bottleDrankMl : undefined,
      bottlePlannedMl: mealType === 'bottle' ? 210 : undefined,
    });
    showSuccess(`Repas enregistré pour ${currentChild.firstName} !`);
  };

  const handleSaveNap = () => {
    if (!currentChild) return;
    if (napAction === 'sleep_start') {
      logNap(currentChild.id, {
        startTime: nowTime,
        isSleeping: true,
        quality: napQuality,
        notes: 'Endormi paisiblement dans le dortoir.',
      });
      showSuccess(`Début de sieste notifié pour ${currentChild.firstName} !`);
    } else {
      logNap(currentChild.id, {
        startTime: '13:00',
        endTime: nowTime,
        durationMinutes: napDurationMinutes,
        isSleeping: false,
        quality: napQuality,
        notes: `Réveil après ${Math.floor(napDurationMinutes / 60)}h${napDurationMinutes % 60}min.`,
      });
      showSuccess(`Réveil notifié aux parents de ${currentChild.firstName} !`);
    }
  };

  const handleSaveDiaper = () => {
    if (!currentChild) return;
    logDiaper(currentChild.id, {
      time: nowTime,
      type: diaperType,
      careApplied,
      needsRefillAlert,
    });
    showSuccess(
      needsRefillAlert
        ? `Alerte stock couches envoyée aux parents de ${currentChild.firstName} !`
        : `Change enregistré pour ${currentChild.firstName} !`
    );
  };

  const handleSaveHealth = () => {
    if (!currentChild) return;
    const isFever = temperature >= 38.0;
    logHealth(currentChild.id, {
      time: nowTime,
      temperature,
      isFever,
      actionTaken: isFever ? (healthAction || 'Gant frais appliqué, surveillance rapprochée') : 'Contrôle normal',
    });
    showSuccess(
      isFever
        ? `⚠️ Alerte fièvre envoyée aux parents de ${currentChild.firstName} !`
        : `Température de ${currentChild.firstName} enregistrée !`
    );
  };

  const handleSavePhoto = () => {
    if (!currentChild) return;
    addMomentPhoto(currentChild.id, {
      url: photoUrl,
      caption: photoCaption,
      time: nowTime,
    });
    showSuccess(`Photo partagée avec les parents de ${currentChild.firstName} !`);
  };

  const handleSaveMood = (mood: ChildMood) => {
    if (!currentChild) return;
    setChildMood(currentChild.id, mood);
    showSuccess(`Humeur de ${currentChild.firstName} mise à jour !`);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-150">
      <div className="relative w-full max-w-lg bg-white rounded-3xl shadow-2xl border border-amber-300 overflow-hidden flex flex-col max-h-[92vh]">
        {/* Modal Top Bar */}
        <div className="p-4 sm:p-5 bg-gradient-to-r from-amber-400 to-[#FFB703] border-b border-amber-300 flex items-center justify-between text-slate-900">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-white flex items-center justify-center text-2xl shadow-xs border border-amber-300">
              ⚡
            </div>
            <div>
              <h2 className="font-heading font-black text-lg tracking-wide uppercase">
                SAISIE RAPIDE TRANSMISSION
              </h2>
              <p className="text-xs text-amber-950 font-medium">
                1 clic pour notifier les parents instantanément
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/80 hover:bg-white text-slate-800 flex items-center justify-center transition shadow-xs"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Success overlay message */}
        {successMessage && (
          <div className="absolute inset-0 z-30 bg-white/95 flex flex-col items-center justify-center p-6 text-center animate-in zoom-in-95 duration-150">
            <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center text-3xl mb-3 shadow-inner">
              <CheckCircle2 className="w-10 h-10" />
            </div>
            <h3 className="font-heading font-black text-xl text-slate-900">{successMessage}</h3>
            <p className="text-xs text-slate-500 mt-1">Notification envoyée sur le mobile des parents 📱</p>
          </div>
        )}

        {/* Child Selector Carousel */}
        <div className="p-3 bg-amber-50 border-b border-amber-200">
          <label className="block text-[11px] font-black uppercase text-amber-900 mb-1.5">
            Pour quel enfant ?
          </label>
          <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-1">
            {childrenList.map((c) => {
              const isSelected = c.id === selectedChildId;
              return (
                <button
                  key={c.id}
                  onClick={() => setSelectedChildId(c.id)}
                  className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-bold transition shrink-0 ${
                    isSelected
                      ? 'bg-amber-500 text-white shadow-sm ring-2 ring-amber-600'
                      : 'bg-white text-slate-700 hover:bg-amber-100 border border-amber-200'
                  }`}
                >
                  <img
                    src={c.photoUrl || 'https://images.unsplash.com/photo-1543332164-6e82f355badc?w=100'}
                    alt={c.firstName}
                    className="w-6 h-6 rounded-full object-cover"
                  />
                  <span>{c.firstName}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Category Big Buttons (Matching the toy bear app cards) */}
        <div className="grid grid-cols-5 p-2 bg-slate-50 border-b border-slate-200 gap-1.5 text-center">
          {[
            { id: 'meal', label: 'Repas', icon: <Utensils className="w-4 h-4" />, color: 'text-amber-600' },
            { id: 'nap', label: 'Sieste', icon: <Moon className="w-4 h-4" />, color: 'text-indigo-600' },
            { id: 'diaper', label: 'Change', icon: <Baby className="w-4 h-4" />, color: 'text-sky-600' },
            { id: 'health', label: 'Santé', icon: <Thermometer className="w-4 h-4" />, color: 'text-rose-600' },
            { id: 'photo', label: 'Photo', icon: <Camera className="w-4 h-4" />, color: 'text-emerald-600' },
          ].map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveTab(cat.id as any)}
              className={`p-2 rounded-2xl flex flex-col items-center justify-center gap-1 transition text-xs font-bold ${
                activeTab === cat.id
                  ? 'bg-white text-slate-900 shadow-sm border border-amber-300 ring-2 ring-amber-400'
                  : 'hover:bg-white/60 text-slate-500'
              }`}
            >
              <span className={`p-1.5 rounded-xl bg-slate-100 ${cat.color}`}>{cat.icon}</span>
              <span>{cat.label}</span>
            </button>
          ))}
        </div>

        {/* Tab Body */}
        <div className="p-4 sm:p-5 overflow-y-auto flex-1 space-y-4">
          {/* TAB 1: REPAS */}
          {activeTab === 'meal' && (
            <div className="space-y-4">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-2">Moment du repas :</label>
                <div className="grid grid-cols-4 gap-2">
                  {[
                    { id: 'lunch', label: 'Déjeuner' },
                    { id: 'snack', label: 'Goûter' },
                    { id: 'bottle', label: 'Biberon' },
                    { id: 'breakfast', label: 'Matin' },
                  ].map((m) => (
                    <button
                      key={m.id}
                      onClick={() => setMealType(m.id as any)}
                      className={`py-2 rounded-xl text-xs font-bold border transition ${
                        mealType === m.id
                          ? 'bg-amber-500 text-white border-amber-600'
                          : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50'
                      }`}
                    >
                      {m.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Big Quantity Selector */}
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-2">
                  Quantité mangée par {currentChild.firstName} :
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {[
                    { id: 'all', label: 'Tout mangé', emoji: '🟢', sub: '100% (vide)' },
                    { id: 'good', label: 'Bien mangé', emoji: '🟡', sub: '75%' },
                    { id: 'little', label: 'Un peu mangé', emoji: '🟠', sub: '25%' },
                    { id: 'none', label: 'Rien / Refusé', emoji: '🔴', sub: '0%' },
                  ].map((q) => (
                    <button
                      key={q.id}
                      onClick={() => setEatenQuantity(q.id as any)}
                      className={`p-3 rounded-2xl border text-center transition ${
                        eatenQuantity === q.id
                          ? 'bg-amber-50 border-amber-500 ring-2 ring-amber-400 font-bold'
                          : 'bg-white border-slate-200 hover:bg-slate-50'
                      }`}
                    >
                      <div className="text-xl mb-1">{q.emoji}</div>
                      <div className="text-xs font-bold text-slate-800">{q.label}</div>
                      <div className="text-[10px] text-slate-400">{q.sub}</div>
                    </button>
                  ))}
                </div>
              </div>

              {mealType === 'bottle' ? (
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    Quantité de lait bue : {bottleDrankMl} ml
                  </label>
                  <input
                    type="range"
                    min="60"
                    max="300"
                    step="30"
                    value={bottleDrankMl}
                    onChange={(e) => setBottleDrankMl(Number(e.target.value))}
                    className="w-full accent-amber-500"
                  />
                  <div className="flex justify-between text-[11px] text-slate-400 font-bold">
                    <span>90 ml</span>
                    <span>150 ml</span>
                    <span>210 ml</span>
                    <span>270 ml</span>
                  </div>
                </div>
              ) : (
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Menu proposé :</label>
                  <input
                    type="text"
                    value={menuDescription}
                    onChange={(e) => setMenuDescription(e.target.value)}
                    className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
                    placeholder="Ex: Gratin de courgettes bio, dos de cabillaud, compote"
                  />
                </div>
              )}

              <button
                onClick={handleSaveMeal}
                className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-amber-400 to-[#FFB703] text-slate-900 font-heading font-black tracking-wide text-sm shadow-md hover:brightness-105 active:scale-98 transition flex items-center justify-center gap-2"
              >
                <span>VALIDER & NOTIFIER LE PARENT</span>
              </button>
            </div>
          )}

          {/* TAB 2: SIESTE */}
          {activeTab === 'nap' && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <button
                  onClick={() => setNapAction('sleep_start')}
                  className={`p-4 rounded-2xl border text-center transition ${
                    napAction === 'sleep_start'
                      ? 'bg-indigo-50 border-indigo-500 ring-2 ring-indigo-400 font-bold'
                      : 'bg-white border-slate-200'
                  }`}
                >
                  <div className="text-2xl mb-1">💤</div>
                  <div className="text-xs font-bold text-slate-800">S'endort maintenant</div>
                  <div className="text-[10px] text-slate-400">Heure : {nowTime}</div>
                </button>

                <button
                  onClick={() => setNapAction('wake_up')}
                  className={`p-4 rounded-2xl border text-center transition ${
                    napAction === 'wake_up'
                      ? 'bg-amber-50 border-amber-500 ring-2 ring-amber-400 font-bold'
                      : 'bg-white border-slate-200'
                  }`}
                >
                  <div className="text-2xl mb-1">☀️</div>
                  <div className="text-xs font-bold text-slate-800">Réveil de sieste</div>
                  <div className="text-[10px] text-slate-400">Calculer la durée</div>
                </button>
              </div>

              {napAction === 'wake_up' && (
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    Durée totale du sommeil : {Math.floor(napDurationMinutes / 60)}h
                    {napDurationMinutes % 60 ? (napDurationMinutes % 60) + 'min' : ''}
                  </label>
                  <input
                    type="range"
                    min="30"
                    max="180"
                    step="15"
                    value={napDurationMinutes}
                    onChange={(e) => setNapDurationMinutes(Number(e.target.value))}
                    className="w-full accent-amber-500"
                  />
                </div>
              )}

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-2">Qualité du dodo :</label>
                <div className="grid grid-cols-3 gap-2">
                  {[
                    { id: 'calm', label: 'Calme & Doux 😴' },
                    { id: 'normal', label: 'Normal 💤' },
                    { id: 'agitated', label: 'Agité / Réveils 🥺' },
                  ].map((q) => (
                    <button
                      key={q.id}
                      onClick={() => setNapQuality(q.id as any)}
                      className={`p-2.5 rounded-xl text-xs font-semibold border transition ${
                        napQuality === q.id
                          ? 'bg-indigo-100 text-indigo-900 border-indigo-400 font-bold'
                          : 'bg-white border-slate-200'
                      }`}
                    >
                      {q.label}
                    </button>
                  ))}
                </div>
              </div>

              <button
                onClick={handleSaveNap}
                className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-amber-400 to-[#FFB703] text-slate-900 font-heading font-black tracking-wide text-sm shadow-md hover:brightness-105 active:scale-98 transition flex items-center justify-center gap-2"
              >
                <span>ENREGISTRER LA SIESTE</span>
              </button>
            </div>
          )}

          {/* TAB 3: CHANGE */}
          {activeTab === 'diaper' && (
            <div className="space-y-4">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-2">État de la couche :</label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {[
                    { id: 'wet', label: 'Pipi / Mouillée', emoji: '💧' },
                    { id: 'clean', label: 'Couche Propre', emoji: '✨' },
                    { id: 'stool', label: 'Selles', emoji: '💩' },
                    { id: 'both', label: 'Pipi + Selles', emoji: '🧷' },
                  ].map((d) => (
                    <button
                      key={d.id}
                      onClick={() => setDiaperType(d.id as any)}
                      className={`p-3 rounded-2xl border text-center transition ${
                        diaperType === d.id
                          ? 'bg-sky-50 border-sky-500 ring-2 ring-sky-400 font-bold'
                          : 'bg-white border-slate-200 hover:bg-slate-50'
                      }`}
                    >
                      <div className="text-2xl mb-1">{d.emoji}</div>
                      <div className="text-xs font-bold text-slate-800">{d.label}</div>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Soin apporté :</label>
                <input
                  type="text"
                  value={careApplied}
                  onChange={(e) => setCareApplied(e.target.value)}
                  className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-sky-500 focus:outline-none"
                  placeholder="Ex: Nettoyage à l'eau, crème de change, sérum phy"
                />
              </div>

              {/* Refill Diapers Reminder Alert */}
              <div className="p-3 bg-amber-50 rounded-2xl border border-amber-300 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="text-xl">⚠️</span>
                  <div>
                    <p className="text-xs font-bold text-amber-900">Rappel stock couches</p>
                    <p className="text-[11px] text-amber-700">Alerter le parent de rapporter des couches demain</p>
                  </div>
                </div>
                <input
                  type="checkbox"
                  checked={needsRefillAlert}
                  onChange={(e) => setNeedsRefillAlert(e.target.checked)}
                  className="w-5 h-5 accent-amber-600 rounded"
                />
              </div>

              <button
                onClick={handleSaveDiaper}
                className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-amber-400 to-[#FFB703] text-slate-900 font-heading font-black tracking-wide text-sm shadow-md hover:brightness-105 active:scale-98 transition flex items-center justify-center gap-2"
              >
                <span>VALIDER LE CHANGE</span>
              </button>
            </div>
          )}

          {/* TAB 4: SANTÉ */}
          {activeTab === 'health' && (
            <div className="space-y-4">
              <div className="text-center p-4 bg-slate-50 rounded-3xl border border-slate-200">
                <span className="text-xs font-bold text-slate-500 uppercase">Température corporelle</span>
                <div
                  className={`text-4xl font-heading font-black my-2 ${
                    temperature >= 38.0 ? 'text-rose-600 animate-pulse' : 'text-emerald-600'
                  }`}
                >
                  {temperature.toFixed(1)} °C
                </div>
                <span
                  className={`text-xs px-3 py-1 rounded-full font-bold ${
                    temperature >= 38.0
                      ? 'bg-rose-100 text-rose-800 border border-rose-300'
                      : 'bg-emerald-100 text-emerald-800'
                  }`}
                >
                  {temperature >= 38.0 ? '🚨 ALERTE FIÈVRE (> 38°C)' : '✅ Température normale'}
                </span>
              </div>

              <div>
                <input
                  type="range"
                  min="36.0"
                  max="40.0"
                  step="0.1"
                  value={temperature}
                  onChange={(e) => setTemperature(Number(e.target.value))}
                  className="w-full accent-rose-500"
                />
                <div className="flex justify-between text-[11px] text-slate-400 font-bold">
                  <span>36.0°C</span>
                  <span>37.0°C</span>
                  <span className="text-rose-600">38.0°C</span>
                  <span>39.5°C</span>
                </div>
              </div>

              {temperature >= 38.0 && (
                <div className="p-3 bg-rose-50 border border-rose-200 rounded-2xl">
                  <label className="text-xs font-bold text-rose-900 block mb-1">
                    Protocole appliqué (visible par le parent) :
                  </label>
                  <input
                    type="text"
                    value={healthAction}
                    onChange={(e) => setHealthAction(e.target.value)}
                    placeholder="Ex: Découvert, gant frais, hydratation, contact parent"
                    className="w-full p-2.5 rounded-xl border border-rose-200 bg-white text-xs focus:ring-2 focus:ring-rose-400 focus:outline-none"
                  />
                </div>
              )}

              <button
                onClick={handleSaveHealth}
                className={`w-full py-3.5 rounded-2xl font-heading font-black tracking-wide text-sm shadow-md transition flex items-center justify-center gap-2 ${
                  temperature >= 38.0
                    ? 'bg-rose-600 hover:bg-rose-700 text-white animate-pulse'
                    : 'bg-gradient-to-r from-amber-400 to-[#FFB703] text-slate-900 hover:brightness-105'
                }`}
              >
                <span>
                  {temperature >= 38.0 ? 'ENVOYER ALERTE FIÈVRE URGENTE' : 'ENREGISTRER LA TEMPÉRATURE'}
                </span>
              </button>
            </div>
          )}

          {/* TAB 5: PHOTO */}
          {activeTab === 'photo' && (
            <div className="space-y-4">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Légende du moment doux :</label>
                <input
                  type="text"
                  value={photoCaption}
                  onChange={(e) => setPhotoCaption(e.target.value)}
                  className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
                  placeholder="Ex: Peinture aux doigts, rires partagés au toboggan"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-2">Aperçu photo :</label>
                <div className="h-44 rounded-2xl overflow-hidden border border-amber-200 shadow-inner relative">
                  <img src={photoUrl} alt="Moment" className="w-full h-full object-cover" />
                  <span className="absolute bottom-2 left-2 bg-black/60 text-white text-[10px] px-2 py-0.5 rounded-full font-medium">
                    Prise aujourd’hui à {nowTime}
                  </span>
                </div>
              </div>

              <div className="flex gap-2">
                {[
                  {
                    url: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
                    label: 'Atelier Peinture',
                  },
                  {
                    url: 'https://images.unsplash.com/photo-1596495577886-d920f1fb7238?w=600&auto=format&fit=crop&q=80',
                    label: 'Parcours Jeux',
                  },
                  {
                    url: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
                    label: 'Tapis Éveil',
                  },
                ].map((ph, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => {
                      setPhotoUrl(ph.url);
                      setPhotoCaption(`Instant magique : ${ph.label} avec ${currentChild.firstName} !`);
                    }}
                    className="flex-1 py-1.5 px-2 rounded-xl border border-slate-200 bg-slate-50 hover:bg-amber-50 text-[11px] font-bold text-slate-700 truncate"
                  >
                    {ph.label}
                  </button>
                ))}
              </div>

              <button
                onClick={handleSavePhoto}
                className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-amber-400 to-[#FFB703] text-slate-900 font-heading font-black tracking-wide text-sm shadow-md hover:brightness-105 active:scale-98 transition flex items-center justify-center gap-2"
              >
                <span>PUBLIER L’INSTANTANÉ AUX PARENTS</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
