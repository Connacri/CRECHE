import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { CourseCategory, CoursePricingType } from '../types';
import { X, Sparkles, Plus } from 'lucide-react';

interface CourseFormModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CourseFormModal: React.FC<CourseFormModalProps> = ({ isOpen, onClose }) => {
  const { addCourse } = useApp();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState<CourseCategory>('sports');
  const [price, setPrice] = useState(45);
  const [coachName, setCoachName] = useState('David Renoir');
  const [room, setRoom] = useState('Salle Éveil & Motricité');
  const [startTime, setStartTime] = useState('14:00');
  const [endTime, setEndTime] = useState('15:00');
  const [days, setDays] = useState('Mercredi');
  const [maxStudents, setMaxStudents] = useState(12);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    addCourse({
      schoolId: 'u-school-1',
      title: title.trim(),
      description: description.trim() || 'Atelier ludique d’éveil et de développement pour les enfants.',
      category,
      season: 'schoolYear',
      level: 'beginner',
      pricingType: 'monthly',
      price,
      currency: 'EUR',
      maxStudents,
      coachId: 'u-coach-1',
      coachName,
      room,
      imageUrl: 'https://images.unsplash.com/photo-1596495577886-d920f1fb7238?w=500',
      status: 'active',
      scheduleDays: days.split(',').map((d) => d.trim()).filter(Boolean),
      startTime,
      endTime,
    });

    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-150">
      <div className="relative w-full max-w-lg bg-white rounded-3xl shadow-2xl border border-amber-300 overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="p-4 sm:p-5 bg-gradient-to-r from-amber-400 to-[#FFB703] border-b border-amber-300 flex items-center justify-between text-slate-900">
          <div className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-2xl bg-white flex items-center justify-center text-xl shadow-xs">
              🧩
            </div>
            <div>
              <h2 className="font-heading font-black text-lg tracking-wide uppercase">
                CRÉER UN COURS OU ATELIER
              </h2>
              <p className="text-xs text-amber-950 font-medium">Programme d'éveil et périscolaire</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/80 hover:bg-white text-slate-800 flex items-center justify-center transition shadow-xs"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-5 overflow-y-auto space-y-4 text-xs">
          <div>
            <label className="font-bold text-slate-700 block mb-1">Titre de l'activité :</label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Ex: Judo des Petits, Éveil Théâtral"
              className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
            />
          </div>

          <div>
            <label className="font-bold text-slate-700 block mb-1">Description :</label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Objectifs pédagogiques, matériel fourni..."
              className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-bold text-slate-700 block mb-1">Catégorie :</label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value as CourseCategory)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              >
                <option value="sports">Sports & Motricité</option>
                <option value="music">Musique & Rythme</option>
                <option value="arts">Arts & Peinture</option>
                <option value="languages">Langues & Anglais</option>
                <option value="sciences">Éveil Nature & Sciences</option>
              </select>
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1">Prix mensuel (€) :</label>
              <input
                type="number"
                value={price}
                onChange={(e) => setPrice(Number(e.target.value))}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-bold text-slate-700 block mb-1">Coach / Animateur :</label>
              <input
                type="text"
                value={coachName}
                onChange={(e) => setCoachName(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1">Salle ou atelier :</label>
              <input
                type="text"
                value={room}
                onChange={(e) => setRoom(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="font-bold text-slate-700 block mb-1">Jour(s) :</label>
              <input
                type="text"
                value={days}
                onChange={(e) => setDays(e.target.value)}
                placeholder="Ex: Mercredi, Samedi"
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1">Début :</label>
              <input
                type="text"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs"
              />
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1">Fin :</label>
              <input
                type="text"
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs"
              />
            </div>
          </div>

          <button
            type="submit"
            className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-amber-400 to-[#FFB703] text-slate-900 font-heading font-black tracking-wide text-sm shadow-md hover:brightness-105 active:scale-98 transition flex items-center justify-center gap-2 mt-4"
          >
            <span>AJOUTER L’ACTIVITÉ AU CATALOGUE</span>
          </button>
        </form>
      </div>
    </div>
  );
};
