import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { ParentNotification } from '../types';
import {
  X,
  Bell,
  CheckCheck,
  AlertTriangle,
  Heart,
  Clock,
  Sparkles,
  Send,
} from 'lucide-react';

interface NotificationDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export const NotificationDrawer: React.FC<NotificationDrawerProps> = ({ isOpen, onClose }) => {
  const {
    notifications,
    markNotificationAsRead,
    clearAllNotifications,
    addCustomNotification,
    selectedChild,
  } = useApp();

  const [activeFilter, setActiveFilter] = useState<'all' | 'meal' | 'nap' | 'alert' | 'photo'>('all');
  const [testSimulating, setTestSimulating] = useState(false);

  if (!isOpen) return null;

  const filtered = notifications.filter((n) => {
    if (activeFilter === 'all') return true;
    if (activeFilter === 'meal') return n.type === 'meal';
    if (activeFilter === 'nap') return n.type === 'nap';
    if (activeFilter === 'alert') return n.type === 'fever' || n.type === 'stock_alert';
    if (activeFilter === 'photo') return n.type === 'photo';
    return true;
  });

  const handleSimulateAlert = () => {
    setTestSimulating(true);
    setTimeout(() => {
      addCustomNotification({
        childId: selectedChild?.id,
        childName: selectedChild?.firstName || 'Léo',
        type: 'meal',
        title: `🥣 Déjeuner terminé (${selectedChild?.firstName || 'Léo'})`,
        message: `${selectedChild?.firstName || 'Léo'} a tout mangé son gratin de potiron et sa compote ! Tout sourire.`,
        priority: 'normal',
        badgeIcon: '🥣',
      });
      setTestSimulating(false);
    }, 600);
  };

  const getPriorityBadge = (priority: ParentNotification['priority']) => {
    if (priority === 'urgent') {
      return (
        <span className="px-2 py-0.5 rounded-full text-[10px] font-black uppercase bg-red-100 text-red-700 border border-red-300 animate-pulse">
          URGENT 🚨
        </span>
      );
    }
    if (priority === 'high') {
      return (
        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-800 border border-amber-300">
          IMPORTANT ⚠️
        </span>
      );
    }
    return null;
  };

  return (
    <div className="fixed inset-0 z-50 flex justify-end animate-in fade-in duration-200">
      {/* Backdrop */}
      <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs" onClick={onClose} />

      {/* Drawer */}
      <div className="relative w-full max-w-md bg-white h-full shadow-2xl flex flex-col z-10 border-l border-amber-200">
        {/* Header */}
        <div className="p-4 sm:p-5 bg-gradient-to-r from-amber-400 to-[#FFB703] border-b border-amber-300 flex items-center justify-between text-slate-900">
          <div className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-2xl bg-white flex items-center justify-center text-xl shadow-xs border border-amber-300">
              🔔
            </div>
            <div>
              <h2 className="font-heading font-black text-lg tracking-wide uppercase">
                NOTIFICATIONS EN DIRECT
              </h2>
              <p className="text-xs text-amber-950 font-medium">Transmissions & alertes instantanées</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/80 hover:bg-white text-slate-800 flex items-center justify-center transition shadow-xs"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Filters and Actions */}
        <div className="p-3 bg-amber-50/80 border-b border-amber-200 flex items-center justify-between gap-2 overflow-x-auto no-scrollbar">
          <div className="flex items-center gap-1.5">
            {[
              { id: 'all', label: 'Toutes' },
              { id: 'meal', label: '🥣 Repas' },
              { id: 'nap', label: '💤 Sieste' },
              { id: 'alert', label: '⚠️ Alertes' },
              { id: 'photo', label: '📸 Photos' },
            ].map((f) => (
              <button
                key={f.id}
                onClick={() => setActiveFilter(f.id as any)}
                className={`px-2.5 py-1 rounded-full text-xs font-bold transition ${
                  activeFilter === f.id
                    ? 'bg-amber-500 text-white shadow-xs'
                    : 'bg-white text-slate-700 hover:bg-amber-100 border border-amber-200'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>
          {notifications.length > 0 && (
            <button
              onClick={clearAllNotifications}
              className="text-xs text-amber-900 hover:text-amber-950 font-semibold underline whitespace-nowrap pl-1"
            >
              Effacer
            </button>
          )}
        </div>

        {/* Notifications List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-[#FFFDF7]">
          {filtered.length === 0 ? (
            <div className="text-center py-12 px-4">
              <div className="w-16 h-16 rounded-full bg-amber-100 text-amber-700 flex items-center justify-center mx-auto mb-3 text-2xl shadow-inner">
                🧸
              </div>
              <h3 className="font-bold text-slate-800 text-sm">Aucune notification pour l'instant</h3>
              <p className="text-xs text-slate-500 mt-1 max-w-xs mx-auto">
                Les transmissions de la crèche (repas, siestes, soins, alertes) apparaîtront ici en direct.
              </p>
            </div>
          ) : (
            filtered.map((item) => (
              <div
                key={item.id}
                onClick={() => markNotificationAsRead(item.id)}
                className={`p-3.5 rounded-2xl border transition relative cursor-pointer ${
                  item.priority === 'urgent'
                    ? 'bg-rose-50 border-rose-300 shadow-sm'
                    : item.priority === 'high'
                    ? 'bg-amber-50 border-amber-300 shadow-xs'
                    : item.isRead
                    ? 'bg-white border-slate-200'
                    : 'bg-amber-50/60 border-amber-300 shadow-xs ring-1 ring-amber-300/60'
                }`}
              >
                {!item.isRead && (
                  <span className="absolute top-3 right-3 w-2.5 h-2.5 bg-amber-500 rounded-full" />
                )}

                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-xl bg-white border border-amber-200 shadow-xs flex items-center justify-center text-lg shrink-0">
                    {item.badgeIcon || '🔔'}
                  </div>

                  <div className="flex-1 pr-4">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-bold text-slate-900 text-xs sm:text-sm">
                        {item.title}
                      </span>
                      {getPriorityBadge(item.priority)}
                    </div>

                    <p className="text-xs text-slate-600 mt-1 leading-relaxed">
                      {item.message}
                    </p>

                    <div className="flex items-center gap-2 mt-2 text-[10px] text-slate-400 font-medium">
                      <span className="flex items-center gap-1">
                        <Clock className="w-3 h-3" /> {item.timestamp}
                      </span>
                      {item.childName && (
                        <span>• Enfant : <strong className="text-slate-600">{item.childName}</strong></span>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Footer with instant test notification button */}
        <div className="p-3.5 bg-white border-t border-amber-200 flex items-center justify-between gap-3">
          <button
            onClick={handleSimulateAlert}
            disabled={testSimulating}
            className="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-bold text-xs transition shadow-sm active:scale-95 disabled:opacity-50"
          >
            <Send className="w-3.5 h-3.5" />
            <span>{testSimulating ? 'Simulation...' : 'Simuler une notif crèche en direct'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
