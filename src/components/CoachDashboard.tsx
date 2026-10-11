import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import {
  GraduationCap,
  Calendar,
  Users,
  CheckCircle2,
  Clock,
  Sparkles,
  ClipboardList,
} from 'lucide-react';

export const CoachDashboard: React.FC = () => {
  const { courses, schedules, childrenList, attendance, toggleAttendance } = useApp();
  const [selectedCourseId, setSelectedCourseId] = useState<string>(courses[0]?.id || '');
  const todayStr = new Date().toISOString().split('T')[0];

  const currentCourse = courses.find((c) => c.id === selectedCourseId) || courses[0];
  const mySchedules = schedules.filter((s) => s.courseId === currentCourse?.id);

  return (
    <div className="space-y-6 pb-20">
      {/* Banner */}
      <div className="rounded-3xl bg-gradient-to-r from-emerald-500 via-teal-500 to-sky-600 p-6 sm:p-8 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/20 text-xs font-black uppercase mb-2">
            <span>🏃 ESPACE COACH & ANIMATEUR</span>
          </div>
          <h1 className="font-heading text-2xl sm:text-3xl font-black uppercase leading-tight">
            SÉANCES & SUIVI PÉDAGOGIQUE
          </h1>
          <p className="text-xs sm:text-sm text-emerald-100 mt-1">
            Feuille d'émargement, appel des élèves et ateliers moteurs
          </p>
        </div>
      </div>

      {/* Course selector tabs */}
      <div className="flex items-center gap-2 overflow-x-auto no-scrollbar">
        {courses.map((c) => (
          <button
            key={c.id}
            onClick={() => setSelectedCourseId(c.id)}
            className={`px-4 py-2 rounded-2xl text-xs font-bold transition whitespace-nowrap shadow-xs ${
              currentCourse?.id === c.id
                ? 'bg-emerald-600 text-white'
                : 'bg-white text-slate-700 hover:bg-emerald-50 border border-slate-200'
            }`}
          >
            {c.title}
          </button>
        ))}
      </div>

      {/* Course Overview & Attendance sheet */}
      {currentCourse && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 bg-white rounded-3xl p-5 sm:p-6 border border-emerald-200 shadow-md space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-heading font-black text-base text-slate-900 uppercase">
                  FEUILLE D'APPEL DU JOUR ({todayStr})
                </h3>
                <p className="text-xs text-slate-500">
                  Cochez les enfants présents à la séance de {currentCourse.title}
                </p>
              </div>
              <span className="px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold">
                Salle : {currentCourse.room || 'Atelier'}
              </span>
            </div>

            <div className="space-y-3">
              {childrenList.map((child) => {
                const att = attendance.find(
                  (a) => a.courseId === currentCourse.id && a.childId === child.id && a.date === todayStr
                );
                const isPresent = att ? att.isPresent : true;

                return (
                  <div
                    key={child.id}
                    className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between gap-3"
                  >
                    <div className="flex items-center gap-3">
                      <img
                        src={child.photoUrl || 'https://images.unsplash.com/photo-1543332164-6e82f355badc?w=100'}
                        alt={child.firstName}
                        className="w-10 h-10 rounded-xl object-cover"
                      />
                      <div>
                        <h4 className="font-bold text-xs text-slate-900">
                          {child.firstName} {child.lastName}
                        </h4>
                        <p className="text-[11px] text-slate-500">{child.groupName}</p>
                        {child.medicalInfo.allergies.length > 0 && (
                          <span className="text-[10px] text-rose-600 font-bold block">
                            ⚠️ {child.medicalInfo.allergies.join(', ')}
                          </span>
                        )}
                      </div>
                    </div>

                    <button
                      onClick={() =>
                        toggleAttendance(currentCourse.id, child.id, todayStr, !isPresent)
                      }
                      className={`px-3.5 py-1.5 rounded-full text-xs font-bold transition shadow-xs ${
                        isPresent
                          ? 'bg-emerald-500 hover:bg-emerald-600 text-white'
                          : 'bg-slate-200 text-slate-600'
                      }`}
                    >
                      {isPresent ? 'PRÉSENT ✅' : 'ABSENT ❌'}
                    </button>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-white rounded-3xl p-5 border border-emerald-200 shadow-md space-y-3">
              <h4 className="font-heading font-black text-sm text-slate-900 uppercase">
                DÉTAILS DU COURS
              </h4>
              <p className="text-xs text-slate-600 leading-relaxed">{currentCourse.description}</p>
              <div className="text-xs space-y-1.5 pt-2 border-t border-slate-100">
                <div className="flex justify-between">
                  <span className="text-slate-400">Jours :</span>
                  <span className="font-bold text-slate-800">{currentCourse.scheduleDays.join(', ')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Horaires :</span>
                  <span className="font-bold text-slate-800">
                    {currentCourse.startTime} - {currentCourse.endTime}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Capacité max :</span>
                  <span className="font-bold text-slate-800">{currentCourse.maxStudents} enfants</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
