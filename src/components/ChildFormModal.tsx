import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { ChildGender } from '../types';
import { X, Baby, Heart, Shield, Plus } from 'lucide-react';

interface ChildFormModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const ChildFormModal: React.FC<ChildFormModalProps> = ({ isOpen, onClose }) => {
  const { addChild, currentUser } = useApp();

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('Dupont');
  const [dateOfBirth, setDateOfBirth] = useState('2023-05-12');
  const [gender, setGender] = useState<ChildGender>('male');
  const [groupName, setGroupName] = useState('Petits Oursons (2-3 ans)');
  const [schoolGrade, setSchoolGrade] = useState('Moyenne Section Crèche');
  const [photoUrl, setPhotoUrl] = useState('https://images.unsplash.com/photo-1543332164-6e82f355badc?w=150');
  const [allergiesText, setAllergiesText] = useState('Arachides');
  const [emergencyContact, setEmergencyContact] = useState('Sophie Dupont (Mère)');
  const [emergencyPhone, setEmergencyPhone] = useState('+33 6 98 76 54 32');
  const [bloodType, setBloodType] = useState('A+');
  const [additionalNotes, setAdditionalNotes] = useState('Doudou lapin indispensable.');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!firstName.trim()) return;

    addChild({
      parentId: currentUser.id,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      dateOfBirth,
      gender,
      photoUrl,
      schoolGrade,
      groupName,
      medicalInfo: {
        allergies: allergiesText
          ? allergiesText.split(',').map((s) => s.trim()).filter(Boolean)
          : [],
        medications: [],
        emergencyContact,
        emergencyPhone,
        bloodType,
        additionalNotes,
      },
      checkInStatus: 'at_home',
      isActive: true,
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
              🧸
            </div>
            <div>
              <h2 className="font-heading font-black text-lg tracking-wide uppercase">
                INSCRIRE UN ENFANT
              </h2>
              <p className="text-xs text-amber-950 font-medium">Fiche d'identité et carnet de santé crèche</p>
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
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-bold text-slate-700 block mb-1">Prénom :</label>
              <input
                type="text"
                required
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                placeholder="Ex: Lucas"
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1">Nom de famille :</label>
              <input
                type="text"
                required
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                placeholder="Ex: Dupont"
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-bold text-slate-700 block mb-1">Date de naissance :</label>
              <input
                type="date"
                required
                value={dateOfBirth}
                onChange={(e) => setDateOfBirth(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1">Genre :</label>
              <select
                value={gender}
                onChange={(e) => setGender(e.target.value as ChildGender)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              >
                <option value="male">Garçon 👦</option>
                <option value="female">Fille 👧</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-bold text-slate-700 block mb-1">Section / Groupe :</label>
              <select
                value={groupName}
                onChange={(e) => setGroupName(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              >
                <option value="Bébés Câlins (10-18 mois)">Bébés Câlins (10-18 mois)</option>
                <option value="Petits Oursons (2-3 ans)">Petits Oursons (2-3 ans)</option>
                <option value="Grands Explorateurs (3-4 ans)">Grands Explorateurs (3-4 ans)</option>
              </select>
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1">Groupe sanguin :</label>
              <input
                type="text"
                value={bloodType}
                onChange={(e) => setBloodType(e.target.value)}
                placeholder="A+, O+, etc."
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
          </div>

          <div>
            <label className="font-bold text-slate-700 block mb-1">
              Allergies connues (séparer par des virgules) :
            </label>
            <input
              type="text"
              value={allergiesText}
              onChange={(e) => setAllergiesText(e.target.value)}
              placeholder="Ex: Arachides, Lactose, Fruits à coque"
              className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-bold text-slate-700 block mb-1">Contact d'urgence (Nom) :</label>
              <input
                type="text"
                value={emergencyContact}
                onChange={(e) => setEmergencyContact(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1">Téléphone d'urgence :</label>
              <input
                type="text"
                value={emergencyPhone}
                onChange={(e) => setEmergencyPhone(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
            </div>
          </div>

          <div>
            <label className="font-bold text-slate-700 block mb-1">Consignes & doudou :</label>
            <textarea
              rows={2}
              value={additionalNotes}
              onChange={(e) => setAdditionalNotes(e.target.value)}
              placeholder="Ex: Tétine pour la sieste, aime les histoires de dinosaures..."
              className="w-full p-2.5 rounded-xl border border-slate-200 text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
            />
          </div>

          <button
            type="submit"
            className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-amber-400 to-[#FFB703] text-slate-900 font-heading font-black tracking-wide text-sm shadow-md hover:brightness-105 active:scale-98 transition flex items-center justify-center gap-2 mt-4"
          >
            <span>ENREGISTRER LA FICHE DE L'ENFANT</span>
          </button>
        </form>
      </div>
    </div>
  );
};
