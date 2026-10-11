import React, { useState } from 'react';
import { useApp } from './context/AppContext';
import { BearHeader } from './components/BearHeader';
import { ParentDashboard } from './components/ParentDashboard';
import { SchoolDashboard } from './components/SchoolDashboard';
import { CoachDashboard } from './components/CoachDashboard';
import { TransporteurDashboard } from './components/TransporteurDashboard';
import { FournisseurDashboard } from './components/FournisseurDashboard';
import { NotificationDrawer } from './components/NotificationDrawer';
import { FastTransmissionModal } from './components/FastTransmissionModal';
import { ChildQrModal } from './components/ChildQrModal';
import { ChildFormModal } from './components/ChildFormModal';
import { CourseFormModal } from './components/CourseFormModal';
import { ProfileModal } from './components/ProfileModal';
import {
  Home,
  Puzzle,
  Utensils,
  ShoppingBag,
  User as UserIcon,
  Bell,
  Sparkles,
} from 'lucide-react';

export const App: React.FC = () => {
  const { currentUser, unreadNotificationsCount, notifications } = useApp();

  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [fastLoggerOpen, setFastLoggerOpen] = useState(false);
  const [fastLoggerChildId, setFastLoggerChildId] = useState<string | undefined>();
  const [qrModalOpen, setQrModalOpen] = useState(false);
  const [childModalOpen, setChildModalOpen] = useState(false);
  const [courseModalOpen, setCourseModalOpen] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);

  // Bottom dock active tab
  const [activeDockTab, setActiveDockTab] = useState<'home' | 'activities' | 'transmissions' | 'shop' | 'profile'>('home');

  const openFastLoggerWithChild = (childId?: string) => {
    setFastLoggerChildId(childId);
    setFastLoggerOpen(true);
  };

  const latestUnread = notifications.find((n) => !n.isRead);

  return (
    <div className="min-h-screen bg-[#FFFDF7] text-slate-800 flex flex-col font-sans selection:bg-amber-400 selection:text-amber-950">
      {/* 1. Bear Header */}
      <BearHeader
        onOpenNotifications={() => setNotificationsOpen(true)}
        onOpenProfile={() => setProfileModalOpen(true)}
        onOpenQrModal={() => setQrModalOpen(true)}
        onOpenAddChildModal={() => setChildModalOpen(true)}
      />

      {/* 2. Live Notification Banner (Simulates push alert at top if unread urgent/high exists) */}
      {latestUnread && latestUnread.priority !== 'normal' && (
        <div className="bg-gradient-to-r from-rose-500 to-amber-500 text-white px-4 py-2.5 shadow-md flex items-center justify-between animate-in slide-in-from-top-4 duration-200">
          <div className="max-w-7xl mx-auto flex items-center gap-2 text-xs sm:text-sm font-bold">
            <span className="text-base animate-bounce">{latestUnread.badgeIcon || '🚨'}</span>
            <span>{latestUnread.title} :</span>
            <span className="font-normal opacity-95 hidden sm:inline">{latestUnread.message}</span>
          </div>
          <button
            onClick={() => setNotificationsOpen(true)}
            className="px-3 py-1 bg-white text-slate-900 rounded-full text-xs font-black uppercase hover:bg-amber-50 shadow-xs shrink-0"
          >
            Voir
          </button>
        </div>
      )}

      {/* 3. Main Dashboard Body based on Current Role */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {currentUser.role === 'parent' && (
          <ParentDashboard
            onOpenNotifications={() => setNotificationsOpen(true)}
            onOpenQrModal={() => setQrModalOpen(true)}
            onOpenFastLogger={() => openFastLoggerWithChild()}
          />
        )}

        {(currentUser.role === 'school' || currentUser.role === 'admin') && (
          <SchoolDashboard
            onOpenFastLogger={openFastLoggerWithChild}
            onOpenNewCourse={() => setCourseModalOpen(true)}
            onOpenNewEvent={() => {}}
          />
        )}

        {currentUser.role === 'coach' && <CoachDashboard />}

        {currentUser.role === 'transporteur' && <TransporteurDashboard />}

        {currentUser.role === 'fournisseur' && <FournisseurDashboard />}
      </main>

      {/* 4. Playful Floating Bottom Navigation Dock (Inspired by the uploaded Bear Baby mockups) */}
      <div className="fixed bottom-3 left-1/2 -translate-x-1/2 z-40 w-11/12 max-w-md">
        <div className="bg-white/95 backdrop-blur-md rounded-full p-1.5 shadow-2xl border border-amber-300 flex items-center justify-around">
          {[
            { id: 'home', label: 'Accueil', icon: <Home className="w-5 h-5" />, action: () => setActiveDockTab('home') },
            { id: 'transmissions', label: 'Transmissions', icon: <Utensils className="w-5 h-5" />, action: () => openFastLoggerWithChild() },
            { id: 'notifs', label: 'Alertes', icon: <Bell className="w-5 h-5" />, action: () => setNotificationsOpen(true), badge: unreadNotificationsCount },
            { id: 'qr', label: 'Badge QR', icon: <Sparkles className="w-5 h-5" />, action: () => setQrModalOpen(true) },
            { id: 'profile', label: 'Profil', icon: <UserIcon className="w-5 h-5" />, action: () => setProfileModalOpen(true) },
          ].map((item) => (
            <button
              key={item.id}
              onClick={item.action}
              className={`relative p-2.5 rounded-full transition flex flex-col items-center justify-center text-slate-500 hover:text-amber-900 ${
                activeDockTab === item.id ? 'bg-amber-400 text-slate-950 font-bold shadow-xs scale-105' : 'hover:bg-amber-50'
              }`}
              title={item.label}
            >
              {item.icon}
              {Boolean(item.badge && item.badge > 0) && (
                <span className="absolute top-1 right-1 w-4 h-4 bg-rose-500 text-white rounded-full text-[9px] font-black flex items-center justify-center">
                  {item.badge}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* 5. Modals & Drawers */}
      <NotificationDrawer
        isOpen={notificationsOpen}
        onClose={() => setNotificationsOpen(false)}
      />

      <FastTransmissionModal
        isOpen={fastLoggerOpen}
        onClose={() => setFastLoggerOpen(false)}
        defaultChildId={fastLoggerChildId}
      />

      <ChildQrModal
        isOpen={qrModalOpen}
        onClose={() => setQrModalOpen(false)}
      />

      <ChildFormModal
        isOpen={childModalOpen}
        onClose={() => setChildModalOpen(false)}
      />

      <CourseFormModal
        isOpen={courseModalOpen}
        onClose={() => setCourseModalOpen(false)}
      />

      <ProfileModal
        isOpen={profileModalOpen}
        onClose={() => setProfileModalOpen(false)}
      />
    </div>
  );
};
