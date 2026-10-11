import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import {
  Users,
  Calendar,
  CreditCard,
  Plus,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  QrCode,
  Sparkles,
  Utensils,
  Moon,
  Baby,
  Thermometer,
  Clock,
  ChevronRight,
  TrendingUp,
  Package,
} from 'lucide-react';

interface SchoolDashboardProps {
  onOpenFastLogger: (childId?: string) => void;
  onOpenNewCourse: () => void;
  onOpenNewEvent: () => void;
}

export const SchoolDashboard: React.FC<SchoolDashboardProps> = ({
  onOpenFastLogger,
  onOpenNewCourse,
  onOpenNewEvent,
}) => {
  const {
    childrenList,
    toggleCheckInStatus,
    transmissions,
    courses,
    enrollments,
    updateEnrollmentStatus,
    schedules,
    events,
    expenses,
    invoices,
    shipments,
  } = useApp();

  const [activeTab, setActiveTab] = useState<'presence' | 'transmissions' | 'courses' | 'enrollments' | 'planning' | 'finances'>('presence');
  const [selectedGroupFilter, setSelectedGroupFilter] = useState<string>('all');

  const presentCount = childrenList.filter((c) => c.checkInStatus === 'checked_in').length;
  const pendingEnrollments = enrollments.filter((e) => e.status === 'pending');
  const totalRevenue = invoices.filter((i) => i.status === 'paid').reduce((acc, i) => acc + i.amount, 0);

  const filteredChildren = childrenList.filter((c) => {
    if (selectedGroupFilter === 'all') return true;
    return c.groupName.toLowerCase().includes(selectedGroupFilter.toLowerCase());
  });

  return (
    <div className="space-y-6 pb-20">
      {/* 1. Header Banner */}
      <div className="rounded-3xl bg-gradient-to-r from-amber-400 via-amber-500 to-orange-500 p-6 sm:p-8 text-slate-900 shadow-xl border border-amber-300 relative overflow-hidden">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/80 text-xs font-black uppercase text-amber-950 mb-2">
              <span>🏫 DIRECTION & ÉDUCATEURS</span>
            </div>
            <h1 className="font-heading text-2xl sm:text-3xl font-black uppercase text-slate-900">
              CRÈCHE & CLUB LES PETITS OURSONS
            </h1>
            <p className="text-xs sm:text-sm font-semibold text-amber-950 mt-1">
              Tableau de bord de pilotage, pointages en temps réel et transmissions quotidiennes
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <button
              onClick={() => onOpenFastLogger()}
              className="px-4 py-2.5 rounded-full bg-white text-slate-900 hover:bg-amber-50 font-heading font-black text-xs sm:text-sm tracking-wide shadow-md transition flex items-center gap-2 active:scale-95"
            >
              <span>⚡ SAISIE RAPIDE (1-CLIC)</span>
            </button>
            <button
              onClick={onOpenNewCourse}
              className="px-3.5 py-2.5 rounded-full bg-amber-900 text-white hover:bg-amber-950 font-bold text-xs shadow-md transition flex items-center gap-1.5"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Nouveau Cours</span>
            </button>
          </div>
        </div>
      </div>

      {/* 2. KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-5">
        <div className="bg-white p-4 sm:p-5 rounded-3xl border border-amber-200 shadow-md">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500">Présents en crèche</span>
            <span className="w-8 h-8 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center text-sm font-bold">
              👶
            </span>
          </div>
          <div className="text-2xl sm:text-3xl font-heading font-black text-slate-900 mt-2">
            {presentCount} <span className="text-xs text-slate-400">/ {childrenList.length}</span>
          </div>
          <span className="text-[11px] font-semibold text-emerald-700 mt-1 block">
            {presentCount === childrenList.length ? 'Tous au complet' : 'Pointages en direct'}
          </span>
        </div>

        <div className="bg-white p-4 sm:p-5 rounded-3xl border border-amber-200 shadow-md">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500">Demandes en cours</span>
            <span className="w-8 h-8 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center text-sm font-bold">
              ⏳
            </span>
          </div>
          <div className="text-2xl sm:text-3xl font-heading font-black text-slate-900 mt-2">
            {pendingEnrollments.length}
          </div>
          <span className="text-[11px] font-semibold text-amber-700 mt-1 block">
            Inscriptions à valider
          </span>
        </div>

        <div className="bg-white p-4 sm:p-5 rounded-3xl border border-amber-200 shadow-md">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500">Cours & Ateliers</span>
            <span className="w-8 h-8 rounded-xl bg-indigo-100 text-indigo-700 flex items-center justify-center text-sm font-bold">
              🧩
            </span>
          </div>
          <div className="text-2xl sm:text-3xl font-heading font-black text-slate-900 mt-2">
            {courses.length}
          </div>
          <span className="text-[11px] font-semibold text-indigo-700 mt-1 block">
            Éveil & Périscolaire
          </span>
        </div>

        <div className="bg-white p-4 sm:p-5 rounded-3xl border border-amber-200 shadow-md">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500">Revenus Encaissés</span>
            <span className="w-8 h-8 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center text-sm font-bold">
              💶
            </span>
          </div>
          <div className="text-2xl sm:text-3xl font-heading font-black text-slate-900 mt-2">
            {totalRevenue} €
          </div>
          <span className="text-[11px] font-semibold text-emerald-700 mt-1 block">
            Factures réglées ce mois
          </span>
        </div>
      </div>

      {/* 3. Navigation Tabs */}
      <div className="bg-white rounded-3xl p-2 border border-amber-200 shadow-sm flex items-center gap-1 overflow-x-auto no-scrollbar">
        {[
          { id: 'presence', label: 'Pointage & Appel', icon: <Users className="w-4 h-4" /> },
          { id: 'transmissions', label: 'Cahier Transmissions', icon: <Utensils className="w-4 h-4" /> },
          { id: 'enrollments', label: `Inscriptions (${pendingEnrollments.length})`, icon: <CheckCircle2 className="w-4 h-4" /> },
          { id: 'courses', label: 'Gestion des Cours', icon: <Sparkles className="w-4 h-4" /> },
          { id: 'planning', label: 'Planning Semaine', icon: <Calendar className="w-4 h-4" /> },
          { id: 'finances', label: 'Finances & Dépenses', icon: <CreditCard className="w-4 h-4" /> },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-2xl text-xs font-bold transition whitespace-nowrap ${
              activeTab === tab.id
                ? 'bg-amber-500 text-white shadow-xs'
                : 'text-slate-600 hover:bg-amber-50'
            }`}
          >
            {tab.icon}
            <span>{tab.label}</span>
          </button>
        ))}
      </div>

      {/* 4. Tab Contents */}

      {/* TAB A: POINTAGE & ARRIVÉES */}
      {activeTab === 'presence' && (
        <div className="bg-white rounded-3xl p-5 sm:p-6 border border-amber-200 shadow-md space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <h3 className="font-heading font-black text-lg text-slate-900 uppercase">
                POINTAGE DES ARRIVÉES ET DÉPARTS
              </h3>
              <p className="text-xs text-slate-500">
                Cochez en un clic pour enregistrer l'arrivée ou le départ de chaque enfant
              </p>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-slate-500">Groupe :</span>
              <select
                value={selectedGroupFilter}
                onChange={(e) => setSelectedGroupFilter(e.target.value)}
                className="px-3 py-1.5 rounded-xl border border-slate-200 text-xs font-semibold focus:outline-none"
              >
                <option value="all">Tous les groupes</option>
                <option value="Oursons">Petits Oursons (2-3 ans)</option>
                <option value="Bébés">Bébés Câlins (10-18 mois)</option>
                <option value="Explorateurs">Grands Explorateurs</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {filteredChildren.map((child) => {
              const isCheckedIn = child.checkInStatus === 'checked_in';
              const trans = transmissions[child.id];
              return (
                <div
                  key={child.id}
                  className={`p-4 rounded-3xl border transition flex items-center justify-between gap-3 ${
                    isCheckedIn
                      ? 'bg-emerald-50/40 border-emerald-300'
                      : 'bg-slate-50 border-slate-200'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <img
                      src={child.photoUrl || 'https://images.unsplash.com/photo-1543332164-6e82f355badc?w=100'}
                      alt={child.firstName}
                      className="w-12 h-12 rounded-2xl object-cover border border-amber-300 shadow-xs"
                    />
                    <div>
                      <h4 className="font-bold text-sm text-slate-900">
                        {child.firstName} {child.lastName}
                      </h4>
                      <p className="text-xs text-slate-500">{child.groupName}</p>
                      {child.medicalInfo.allergies.length > 0 && (
                        <span className="inline-block px-2 py-0.5 rounded-full bg-rose-100 text-rose-800 text-[10px] font-bold border border-rose-300 mt-1">
                          ⚠️ Allergie : {child.medicalInfo.allergies.join(', ')}
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="flex flex-col items-end gap-2">
                    <button
                      onClick={() =>
                        toggleCheckInStatus(
                          child.id,
                          isCheckedIn ? 'picked_up' : 'checked_in'
                        )
                      }
                      className={`px-3.5 py-1.5 rounded-full text-xs font-black uppercase transition shadow-xs ${
                        isCheckedIn
                          ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
                          : 'bg-slate-200 hover:bg-slate-300 text-slate-800'
                      }`}
                    >
                      {isCheckedIn ? '🟢 PRÉSENT' : '⚪ ABSENT'}
                    </button>

                    <button
                      onClick={() => onOpenFastLogger(child.id)}
                      className="text-[11px] font-bold text-amber-800 hover:underline"
                    >
                      ⚡ Noter transmission
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* TAB B: CAHIER TRANSMISSIONS */}
      {activeTab === 'transmissions' && (
        <div className="bg-white rounded-3xl p-5 sm:p-6 border border-amber-200 shadow-md space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-heading font-black text-lg text-slate-900 uppercase">
                CAHIER DE TRANSMISSIONS DU JOUR
              </h3>
              <p className="text-xs text-slate-500">
                Vue récapitulative des repas, siestes, changes et consignes parentales
              </p>
            </div>
            <button
              onClick={() => onOpenFastLogger()}
              className="px-3.5 py-1.5 rounded-full bg-amber-500 text-white font-bold text-xs hover:bg-amber-600 transition"
            >
              + Nouvelle saisie
            </button>
          </div>

          <div className="space-y-4">
            {childrenList.map((child) => {
              const trans = transmissions[child.id];
              return (
                <div key={child.id} className="p-4 rounded-2xl bg-amber-50/40 border border-amber-200 space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <strong className="text-sm text-slate-900">{child.firstName} {child.lastName}</strong>
                      <span className="text-xs text-slate-500">({child.groupName})</span>
                    </div>
                    <button
                      onClick={() => onOpenFastLogger(child.id)}
                      className="px-2.5 py-1 rounded-xl bg-white text-amber-900 font-bold text-xs border border-amber-300 shadow-xs hover:bg-amber-50"
                    >
                      Ajouter une note
                    </button>
                  </div>

                  {trans?.parentMorningNote && (
                    <div className="p-2.5 rounded-xl bg-white border border-amber-200 text-xs text-slate-700">
                      <strong className="text-amber-800">Mot du parent ce matin :</strong> « {trans.parentMorningNote} »
                    </div>
                  )}

                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                    <div className="p-2 rounded-xl bg-white border border-slate-200">
                      <span className="font-bold text-slate-600">🥣 Repas :</span>
                      <p className="text-[11px] text-slate-500 mt-0.5">
                        {trans?.meals.length ? `${trans.meals.length} noté(s)` : 'Non noté'}
                      </p>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-slate-200">
                      <span className="font-bold text-slate-600">💤 Sieste :</span>
                      <p className="text-[11px] text-slate-500 mt-0.5">
                        {trans?.naps.length ? `${trans.naps.length} sieste(s)` : 'Non noté'}
                      </p>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-slate-200">
                      <span className="font-bold text-slate-600">🧷 Changes :</span>
                      <p className="text-[11px] text-slate-500 mt-0.5">
                        {trans?.diapers.length ? `${trans.diapers.length} change(s)` : 'Non noté'}
                      </p>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-slate-200">
                      <span className="font-bold text-slate-600">🌡️ Température :</span>
                      <p className="text-[11px] text-slate-500 mt-0.5">
                        {trans?.health.length ? `${trans.health[0].temperature}°C` : 'Normale'}
                      </p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* TAB C: DEMANDES D'INSCRIPTION */}
      {activeTab === 'enrollments' && (
        <div className="bg-white rounded-3xl p-5 sm:p-6 border border-amber-200 shadow-md space-y-4">
          <h3 className="font-heading font-black text-lg text-slate-900 uppercase">
            VALIDATION DES DEMANDES D'INSCRIPTION
          </h3>

          {enrollments.length === 0 ? (
            <p className="text-xs text-slate-500 py-4 text-center">Aucune inscription pour l'instant.</p>
          ) : (
            <div className="space-y-3">
              {enrollments.map((enr) => (
                <div
                  key={enr.id}
                  className="p-4 rounded-2xl border border-slate-200 bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                >
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm text-slate-900">{enr.childName}</span>
                      <span className="text-xs text-slate-500">({enr.parentName})</span>
                    </div>
                    <p className="text-xs text-amber-800 font-semibold mt-0.5">
                      Cours : {enr.courseTitle} • {enr.price} €
                    </p>
                    {enr.notes && <p className="text-[11px] text-slate-500 italic">Note : {enr.notes}</p>}
                  </div>

                  <div className="flex items-center gap-2">
                    {enr.status === 'pending' ? (
                      <>
                        <button
                          onClick={() => updateEnrollmentStatus(enr.id, 'approved', 'paid')}
                          className="px-3.5 py-1.5 rounded-full bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs shadow-xs transition"
                        >
                          Approuver
                        </button>
                        <button
                          onClick={() => updateEnrollmentStatus(enr.id, 'rejected')}
                          className="px-3.5 py-1.5 rounded-full bg-rose-100 hover:bg-rose-200 text-rose-700 font-bold text-xs transition"
                        >
                          Refuser
                        </button>
                      </>
                    ) : (
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-bold ${
                          enr.status === 'approved'
                            ? 'bg-emerald-100 text-emerald-800'
                            : 'bg-rose-100 text-rose-800'
                        }`}
                      >
                        {enr.status === 'approved' ? 'Approuvée ✅' : 'Refusée ❌'}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB D: GESTION DES COURS */}
      {activeTab === 'courses' && (
        <div className="bg-white rounded-3xl p-5 sm:p-6 border border-amber-200 shadow-md space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-heading font-black text-lg text-slate-900 uppercase">
              COURS & ATELIERS PÉRISCOLAIRES
            </h3>
            <button
              onClick={onOpenNewCourse}
              className="px-3.5 py-1.5 rounded-full bg-amber-500 text-white font-bold text-xs hover:bg-amber-600 transition"
            >
              + Ajouter cours
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {courses.map((course) => (
              <div
                key={course.id}
                className="p-4 rounded-3xl border border-amber-200 bg-amber-50/30 flex gap-4"
              >
                <img
                  src={course.imageUrl || 'https://images.unsplash.com/photo-1596495577886-d920f1fb7238?w=300'}
                  alt={course.title}
                  className="w-20 h-20 rounded-2xl object-cover shrink-0 border border-amber-300"
                />
                <div className="flex-1">
                  <h4 className="font-bold text-sm text-slate-900">{course.title}</h4>
                  <p className="text-xs text-slate-600 line-clamp-2 mt-0.5">{course.description}</p>
                  <div className="flex items-center gap-2 mt-2 text-xs font-semibold text-amber-900">
                    <span>{course.price} €/mois</span>
                    <span>•</span>
                    <span>Coach : {course.coachName}</span>
                  </div>
                  <div className="flex items-center gap-1.5 text-[11px] text-slate-400 mt-1">
                    <span>Créneaux : {course.scheduleDays.join(', ')} ({course.startTime} - {course.endTime})</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB E: PLANNING SEMAINIER */}
      {activeTab === 'planning' && (
        <div className="bg-white rounded-3xl p-5 sm:p-6 border border-amber-200 shadow-md space-y-4">
          <h3 className="font-heading font-black text-lg text-slate-900 uppercase">
            EMPLOI DU TEMPS HEBDOMADAIRE (SÉANCES)
          </h3>
          <div className="space-y-3">
            {['Mardi', 'Mercredi', 'Jeudi', 'Samedi'].map((day) => {
              const daySchedules = schedules.filter((s) => s.dayName.toLowerCase() === day.toLowerCase());
              return (
                <div key={day} className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200">
                  <h4 className="font-bold text-xs uppercase text-amber-900 mb-2">🗓️ {day}</h4>
                  {daySchedules.length === 0 ? (
                    <p className="text-[11px] text-slate-400">Aucune séance ce jour-là.</p>
                  ) : (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                      {daySchedules.map((s) => (
                        <div
                          key={s.id}
                          className="p-2.5 rounded-xl bg-white border border-amber-200 text-xs shadow-xs"
                        >
                          <span className="font-bold text-slate-900">{s.courseTitle}</span>
                          <p className="text-[11px] text-slate-500">
                            {s.startTime} - {s.endTime} • Salle : {s.room}
                          </p>
                          <span className="text-[10px] text-amber-700 font-semibold">
                            Coach : {s.coachName}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* TAB F: FINANCES */}
      {activeTab === 'finances' && (
        <div className="bg-white rounded-3xl p-5 sm:p-6 border border-amber-200 shadow-md space-y-5">
          <h3 className="font-heading font-black text-lg text-slate-900 uppercase">
            COMPTABILITÉ & FACTURES ÉMISES
          </h3>

          <div className="space-y-3">
            <h4 className="text-xs font-bold text-slate-500 uppercase">Factures du mois :</h4>
            {invoices.map((inv) => (
              <div
                key={inv.id}
                className="p-3 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between text-xs"
              >
                <div>
                  <span className="font-bold text-slate-900">{inv.childName} ({inv.parentName})</span>
                  <p className="text-[11px] text-slate-500">{inv.courseTitle}</p>
                </div>
                <div className="flex items-center gap-3">
                  <strong className="text-sm font-black">{inv.amount} €</strong>
                  <span
                    className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                      inv.status === 'paid' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
                    }`}
                  >
                    {inv.status === 'paid' ? 'Payé ✅' : 'En attente ⏳'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
