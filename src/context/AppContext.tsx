import React, { createContext, useContext, useState, useEffect, useMemo } from 'react';
import {
  User,
  UserRole,
  Language,
  Child,
  Course,
  Enrollment,
  SessionSchedule,
  ClubEvent,
  ClubExpense,
  ClubInvoice,
  Shipment,
  AttendanceRecord,
  DailyTransmission,
  ParentNotification,
  MealLog,
  NapLog,
  DiaperLog,
  HealthLog,
  ChildMood,
  MomentPhoto,
} from '../types';
import {
  initialUsers,
  initialChildren,
  initialTransmissions,
  initialNotifications,
  initialCourses,
  initialEnrollments,
  initialSchedules,
  initialEvents,
  initialExpenses,
  initialInvoices,
  initialShipments,
} from '../data/mockData';

interface AppContextType {
  currentUser: User;
  setCurrentUser: (user: User) => void;
  switchRole: (role: UserRole) => void;
  users: User[];
  language: Language;
  setLanguage: (lang: Language) => void;

  // Children
  childrenList: Child[];
  selectedChildId: string;
  setSelectedChildId: (id: string) => void;
  selectedChild: Child | undefined;
  addChild: (child: Omit<Child, 'id' | 'createdAt' | 'updatedAt' | 'qrCodeToken'>) => void;
  updateChild: (id: string, updates: Partial<Child>) => void;
  toggleCheckInStatus: (id: string, status: Child['checkInStatus']) => void;

  // Transmissions
  transmissions: Record<string, DailyTransmission>;
  getChildTransmission: (childId: string) => DailyTransmission;
  logMeal: (childId: string, meal: Omit<MealLog, 'id'>) => void;
  logNap: (childId: string, nap: Omit<NapLog, 'id'>) => void;
  logDiaper: (childId: string, diaper: Omit<DiaperLog, 'id'>) => void;
  logHealth: (childId: string, health: Omit<HealthLog, 'id'>) => void;
  setChildMood: (childId: string, mood: ChildMood) => void;
  addMomentPhoto: (childId: string, photo: Omit<MomentPhoto, 'id' | 'likes'>) => void;
  togglePhotoLike: (childId: string, photoId: string) => void;
  setParentMorningNote: (childId: string, note: string) => void;
  setStaffDayNote: (childId: string, note: string) => void;

  // Notifications
  notifications: ParentNotification[];
  unreadNotificationsCount: number;
  markNotificationAsRead: (id: string) => void;
  clearAllNotifications: () => void;
  addCustomNotification: (notif: Omit<ParentNotification, 'id' | 'timestamp' | 'isRead'>) => void;

  // Courses & Enrollments
  courses: Course[];
  addCourse: (course: Omit<Course, 'id' | 'createdAt' | 'enrolledCount'>) => void;
  enrollments: Enrollment[];
  enrollChild: (courseId: string, childId: string, notes?: string) => void;
  updateEnrollmentStatus: (id: string, status: Enrollment['status'], paymentStatus?: Enrollment['paymentStatus']) => void;

  // Timetable
  schedules: SessionSchedule[];
  addSchedule: (sch: Omit<SessionSchedule, 'id'>) => void;

  // Events
  events: ClubEvent[];
  addEvent: (evt: Omit<ClubEvent, 'id' | 'registeredCount'>) => void;
  registerForEvent: (eventId: string) => void;

  // Finance
  expenses: ClubExpense[];
  addExpense: (exp: Omit<ClubExpense, 'id'>) => void;
  invoices: ClubInvoice[];
  addInvoice: (inv: Omit<ClubInvoice, 'id'>) => void;
  payInvoice: (id: string) => void;

  // Logistics
  shipments: Shipment[];
  updateShipmentStatus: (id: string, status: Shipment['status']) => void;
  addShipment: (ship: Omit<Shipment, 'id' | 'createdAt'>) => void;

  // Attendance
  attendance: AttendanceRecord[];
  toggleAttendance: (courseId: string, childId: string, date: string, isPresent: boolean, notes?: string) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>(() => {
    return (localStorage.getItem('creche_language') as Language) || 'fr';
  });

  const [currentUser, setCurrentUserState] = useState<User>(() => {
    const saved = localStorage.getItem('creche_user');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        // ignore
      }
    }
    return initialUsers[0]; // Default: Marc Dupont (Parent)
  });

  const [childrenList, setChildrenList] = useState<Child[]>(() => {
    const saved = localStorage.getItem('creche_children');
    return saved ? JSON.parse(saved) : initialChildren;
  });

  const [selectedChildId, setSelectedChildId] = useState<string>(() => {
    return childrenList[0]?.id || 'c-leo-1';
  });

  const [transmissions, setTransmissions] = useState<Record<string, DailyTransmission>>(() => {
    const saved = localStorage.getItem('creche_transmissions');
    return saved ? JSON.parse(saved) : initialTransmissions;
  });

  const [notifications, setNotifications] = useState<ParentNotification[]>(() => {
    const saved = localStorage.getItem('creche_notifications');
    return saved ? JSON.parse(saved) : initialNotifications;
  });

  const [courses, setCourses] = useState<Course[]>(() => {
    const saved = localStorage.getItem('creche_courses');
    return saved ? JSON.parse(saved) : initialCourses;
  });

  const [enrollments, setEnrollments] = useState<Enrollment[]>(() => {
    const saved = localStorage.getItem('creche_enrollments');
    return saved ? JSON.parse(saved) : initialEnrollments;
  });

  const [schedules, setSchedules] = useState<SessionSchedule[]>(() => {
    const saved = localStorage.getItem('creche_schedules');
    return saved ? JSON.parse(saved) : initialSchedules;
  });

  const [events, setEvents] = useState<ClubEvent[]>(() => {
    const saved = localStorage.getItem('creche_events');
    return saved ? JSON.parse(saved) : initialEvents;
  });

  const [expenses, setExpenses] = useState<ClubExpense[]>(() => {
    const saved = localStorage.getItem('creche_expenses');
    return saved ? JSON.parse(saved) : initialExpenses;
  });

  const [invoices, setInvoices] = useState<ClubInvoice[]>(() => {
    const saved = localStorage.getItem('creche_invoices');
    return saved ? JSON.parse(saved) : initialInvoices;
  });

  const [shipments, setShipments] = useState<Shipment[]>(() => {
    const saved = localStorage.getItem('creche_shipments');
    return saved ? JSON.parse(saved) : initialShipments;
  });

  const [attendance, setAttendance] = useState<AttendanceRecord[]>(() => {
    const saved = localStorage.getItem('creche_attendance');
    return saved ? JSON.parse(saved) : [
      { id: 'att-1', courseId: 'course-1', date: new Date().toISOString().split('T')[0], childId: 'c-leo-1', childName: 'Léo Dupont', isPresent: true },
    ];
  });

  // Sync to storage
  useEffect(() => {
    localStorage.setItem('creche_user', JSON.stringify(currentUser));
  }, [currentUser]);

  useEffect(() => {
    localStorage.setItem('creche_language', language);
  }, [language]);

  useEffect(() => {
    localStorage.setItem('creche_children', JSON.stringify(childrenList));
  }, [childrenList]);

  useEffect(() => {
    localStorage.setItem('creche_transmissions', JSON.stringify(transmissions));
  }, [transmissions]);

  useEffect(() => {
    localStorage.setItem('creche_notifications', JSON.stringify(notifications));
  }, [notifications]);

  useEffect(() => {
    localStorage.setItem('creche_courses', JSON.stringify(courses));
  }, [courses]);

  useEffect(() => {
    localStorage.setItem('creche_enrollments', JSON.stringify(enrollments));
  }, [enrollments]);

  useEffect(() => {
    localStorage.setItem('creche_expenses', JSON.stringify(expenses));
  }, [expenses]);

  useEffect(() => {
    localStorage.setItem('creche_invoices', JSON.stringify(invoices));
  }, [invoices]);

  useEffect(() => {
    localStorage.setItem('creche_shipments', JSON.stringify(shipments));
  }, [shipments]);

  const setLanguage = (lang: Language) => setLanguageState(lang);
  const setCurrentUser = (user: User) => setCurrentUserState(user);

  const switchRole = (role: UserRole) => {
    const found = initialUsers.find((u) => u.role === role);
    if (found) {
      setCurrentUserState(found);
    } else {
      setCurrentUserState({
        id: `u-${role}-gen`,
        email: `${role}@creche.com`,
        fullName: `Utilisateur ${role.toUpperCase()}`,
        role: role,
        isActive: true,
        createdAt: new Date().toISOString(),
      });
    }
  };

  const selectedChild = useMemo(() => {
    return childrenList.find((c) => c.id === selectedChildId) || childrenList[0];
  }, [childrenList, selectedChildId]);

  const unreadNotificationsCount = useMemo(() => {
    return notifications.filter((n) => !n.isRead).length;
  }, [notifications]);

  const getChildTransmission = (childId: string): DailyTransmission => {
    const today = new Date().toISOString().split('T')[0];
    if (!transmissions[childId]) {
      return {
        id: `trans-${childId}-${today}`,
        childId,
        date: today,
        meals: [],
        naps: [],
        diapers: [],
        health: [],
        mood: 'happy',
        photos: [],
      };
    }
    return transmissions[childId];
  };

  const addCustomNotification = (notifData: Omit<ParentNotification, 'id' | 'timestamp' | 'isRead'>) => {
    const nowTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const newNotif: ParentNotification = {
      ...notifData,
      id: `notif-${Date.now()}`,
      timestamp: nowTime,
      isRead: false,
    };
    setNotifications((prev) => [newNotif, ...prev]);
  };

  const markNotificationAsRead = (id: string) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, isRead: true } : n))
    );
  };

  const clearAllNotifications = () => {
    setNotifications([]);
  };

  const addChild = (newChildData: Omit<Child, 'id' | 'createdAt' | 'updatedAt' | 'qrCodeToken'>) => {
    const id = `c-${Date.now()}`;
    const token = `CRECHE-BEAR-${newChildData.firstName.toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const newChild: Child = {
      ...newChildData,
      id,
      qrCodeToken: token,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    setChildrenList((prev) => [newChild, ...prev]);
    setSelectedChildId(id);
  };

  const updateChild = (id: string, updates: Partial<Child>) => {
    setChildrenList((prev) =>
      prev.map((c) => (c.id === id ? { ...c, ...updates, updatedAt: new Date().toISOString() } : c))
    );
  };

  const toggleCheckInStatus = (id: string, status: Child['checkInStatus']) => {
    const nowTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const child = childrenList.find((c) => c.id === id);
    const childName = child?.firstName || 'Enfant';

    updateChild(id, {
      checkInStatus: status,
      lastCheckInTime: status === 'at_home' ? undefined : nowTime,
    });

    if (status === 'checked_in') {
      addCustomNotification({
        childId: id,
        childName,
        type: 'checkin',
        title: `🧸 ${childName} est bien arrivé(e) à la crèche`,
        message: `${childName} a été accueilli(e) par l'équipe à ${nowTime}. Excellente journée en perspective !`,
        priority: 'normal',
        badgeIcon: '🧸',
      });
    } else if (status === 'picked_up') {
      addCustomNotification({
        childId: id,
        childName,
        type: 'checkin',
        title: `👋 ${childName} a été récupéré(e)`,
        message: `${childName} quitte la crèche à ${nowTime} avec un accompagnateur autorisé. À demain !`,
        priority: 'normal',
        badgeIcon: '👋',
      });
    }
  };

  // Logging methods with automatic parent push notification
  const logMeal = (childId: string, mealData: Omit<MealLog, 'id'>) => {
    const child = childrenList.find((c) => c.id === childId);
    const childName = child?.firstName || 'Votre enfant';
    const meal: MealLog = { ...mealData, id: `m-${Date.now()}` };

    setTransmissions((prev) => {
      const current = prev[childId] || getChildTransmission(childId);
      return {
        ...prev,
        [childId]: {
          ...current,
          meals: [meal, ...current.meals],
        },
      };
    });

    const quantityLabels = {
      all: 'a tout mangé avec grand appétit 🟢',
      good: 'a bien mangé 🟡',
      little: 'a mangé un tout petit peu 🟠',
      none: 'a refusé son plat 🔴',
    };

    addCustomNotification({
      childId,
      childName,
      type: 'meal',
      title: `🥣 ${meal.title} (${childName})`,
      message: `${childName} ${quantityLabels[meal.quantity]} : ${meal.menuDescription}`,
      priority: meal.quantity === 'none' ? 'high' : 'normal',
      badgeIcon: '🥣',
    });
  };

  const logNap = (childId: string, napData: Omit<NapLog, 'id'>) => {
    const child = childrenList.find((c) => c.id === childId);
    const childName = child?.firstName || 'Votre enfant';
    const nap: NapLog = { ...napData, id: `n-${Date.now()}` };

    setTransmissions((prev) => {
      const current = prev[childId] || getChildTransmission(childId);
      return {
        ...prev,
        [childId]: {
          ...current,
          naps: [nap, ...current.naps],
        },
      };
    });

    if (nap.isSleeping) {
      addCustomNotification({
        childId,
        childName,
        type: 'nap',
        title: `💤 Sieste en cours pour ${childName}`,
        message: `${childName} s'est endormi(e) paisiblement à ${nap.startTime}. Dortoir calme.`,
        priority: 'normal',
        badgeIcon: '💤',
      });
    } else {
      const durationStr = nap.durationMinutes ? `${Math.floor(nap.durationMinutes / 60)}h${nap.durationMinutes % 60 ? (nap.durationMinutes % 60) + 'min' : ''}` : 'moment';
      addCustomNotification({
        childId,
        childName,
        type: 'nap',
        title: `☀️ Réveil de sieste (${childName})`,
        message: `${childName} est réveillé(e) après ${durationStr} de sommeil réparateur. Humeur calme !`,
        priority: 'normal',
        badgeIcon: '☀️',
      });
    }
  };

  const logDiaper = (childId: string, diaperData: Omit<DiaperLog, 'id'>) => {
    const child = childrenList.find((c) => c.id === childId);
    const childName = child?.firstName || 'Votre enfant';
    const diaper: DiaperLog = { ...diaperData, id: `d-${Date.now()}` };

    setTransmissions((prev) => {
      const current = prev[childId] || getChildTransmission(childId);
      return {
        ...prev,
        [childId]: {
          ...current,
          diapers: [diaper, ...current.diapers],
        },
      };
    });

    if (diaper.needsRefillAlert) {
      addCustomNotification({
        childId,
        childName,
        type: 'stock_alert',
        title: `⚠️ Couches : Stock faible pour ${childName}`,
        message: `Il ne reste que 1 ou 2 couches dans le casier de ${childName}. Merci d'apporter un paquet demain matin !`,
        priority: 'high',
        badgeIcon: '🧷',
      });
    } else {
      addCustomNotification({
        childId,
        childName,
        type: 'diaper',
        title: `🧷 Change effectué (${childName})`,
        message: `Change fait à ${diaper.time} : ${diaper.careApplied || 'Soin doux habituel'}.`,
        priority: 'normal',
        badgeIcon: '🧷',
      });
    }
  };

  const logHealth = (childId: string, healthData: Omit<HealthLog, 'id'>) => {
    const child = childrenList.find((c) => c.id === childId);
    const childName = child?.firstName || 'Votre enfant';
    const health: HealthLog = { ...healthData, id: `h-${Date.now()}` };

    setTransmissions((prev) => {
      const current = prev[childId] || getChildTransmission(childId);
      return {
        ...prev,
        [childId]: {
          ...current,
          health: [health, ...current.health],
        },
      };
    });

    if (health.isFever) {
      addCustomNotification({
        childId,
        childName,
        type: 'fever',
        title: `🚨 Alerte Fièvre : ${health.temperature}°C pour ${childName}`,
        message: `Température mesurée à ${health.temperature}°C à ${health.time}. Action : ${health.actionTaken || 'Gant frais et surveillance rapprochée. Nous vous appelons si besoin.'}`,
        priority: 'urgent',
        badgeIcon: '🌡️',
      });
    } else {
      addCustomNotification({
        childId,
        childName,
        type: 'general',
        title: `🌡️ Contrôle température normal (${childName})`,
        message: `Température de ${health.temperature}°C mesurée à ${health.time}. Tout va très bien.`,
        priority: 'normal',
        badgeIcon: '🌡️',
      });
    }
  };

  const setChildMood = (childId: string, mood: ChildMood) => {
    setTransmissions((prev) => {
      const current = prev[childId] || getChildTransmission(childId);
      return {
        ...prev,
        [childId]: {
          ...current,
          mood,
        },
      };
    });
  };

  const addMomentPhoto = (childId: string, photoData: Omit<MomentPhoto, 'id' | 'likes'>) => {
    const child = childrenList.find((c) => c.id === childId);
    const childName = child?.firstName || 'Votre enfant';
    const photo: MomentPhoto = {
      ...photoData,
      id: `ph-${Date.now()}`,
      likes: 1,
      hasLiked: false,
    };

    setTransmissions((prev) => {
      const current = prev[childId] || getChildTransmission(childId);
      return {
        ...prev,
        [childId]: {
          ...current,
          photos: [photo, ...current.photos],
        },
      };
    });

    addCustomNotification({
      childId,
      childName,
      type: 'photo',
      title: `📸 Instantané partagé (${childName})`,
      message: `${photo.caption}`,
      priority: 'normal',
      badgeIcon: '📸',
    });
  };

  const togglePhotoLike = (childId: string, photoId: string) => {
    setTransmissions((prev) => {
      const current = prev[childId];
      if (!current) return prev;
      return {
        ...prev,
        [childId]: {
          ...current,
          photos: current.photos.map((p) =>
            p.id === photoId
              ? {
                  ...p,
                  hasLiked: !p.hasLiked,
                  likes: p.hasLiked ? p.likes - 1 : p.likes + 1,
                }
              : p
          ),
        },
      };
    });
  };

  const setParentMorningNote = (childId: string, note: string) => {
    setTransmissions((prev) => {
      const current = prev[childId] || getChildTransmission(childId);
      return {
        ...prev,
        [childId]: {
          ...current,
          parentMorningNote: note,
        },
      };
    });
  };

  const setStaffDayNote = (childId: string, note: string) => {
    setTransmissions((prev) => {
      const current = prev[childId] || getChildTransmission(childId);
      return {
        ...prev,
        [childId]: {
          ...current,
          staffNotes: note,
        },
      };
    });
  };

  const addCourse = (courseData: Omit<Course, 'id' | 'createdAt' | 'enrolledCount'>) => {
    const newCourse: Course = {
      ...courseData,
      id: `course-${Date.now()}`,
      enrolledCount: 0,
      createdAt: new Date().toISOString(),
    };
    setCourses((prev) => [newCourse, ...prev]);
  };

  const enrollChild = (courseId: string, childId: string, notes?: string) => {
    const targetCourse = courses.find((c) => c.id === courseId);
    const targetChild = childrenList.find((c) => c.id === childId);
    if (!targetCourse || !targetChild) return;

    const existing = enrollments.find(
      (e) => e.courseId === courseId && e.childId === childId && e.status !== 'rejected' && e.status !== 'cancelled'
    );
    if (existing) return;

    const newEnr: Enrollment = {
      id: `enr-${Date.now()}`,
      courseId,
      courseTitle: targetCourse.title,
      childId,
      childName: `${targetChild.firstName} ${targetChild.lastName}`,
      parentId: currentUser.id,
      parentName: currentUser.fullName,
      schoolId: targetCourse.schoolId,
      status: 'pending',
      paymentStatus: 'pending',
      price: targetCourse.price,
      enrolledAt: new Date().toISOString(),
      notes,
    };

    setEnrollments((prev) => [newEnr, ...prev]);
    setCourses((prev) =>
      prev.map((c) => (c.id === courseId ? { ...c, enrolledCount: c.enrolledCount + 1 } : c))
    );
  };

  const updateEnrollmentStatus = (
    id: string,
    status: Enrollment['status'],
    paymentStatus?: Enrollment['paymentStatus']
  ) => {
    setEnrollments((prev) =>
      prev.map((e) => (e.id === id ? { ...e, status, paymentStatus: paymentStatus || e.paymentStatus } : e))
    );
  };

  const addSchedule = (sch: Omit<SessionSchedule, 'id'>) => {
    const newSch: SessionSchedule = { ...sch, id: `sch-${Date.now()}` };
    setSchedules((prev) => [...prev, newSch]);
  };

  const addEvent = (evt: Omit<ClubEvent, 'id' | 'registeredCount'>) => {
    const newEvt: ClubEvent = { ...evt, id: `evt-${Date.now()}`, registeredCount: 0 };
    setEvents((prev) => [newEvt, ...prev]);
  };

  const registerForEvent = (eventId: string) => {
    setEvents((prev) =>
      prev.map((e) =>
        e.id === eventId && e.registeredCount < e.maxParticipants
          ? { ...e, registeredCount: e.registeredCount + 1 }
          : e
      )
    );
  };

  const addExpense = (exp: Omit<ClubExpense, 'id'>) => {
    const newExp: ClubExpense = { ...exp, id: `exp-${Date.now()}` };
    setExpenses((prev) => [newExp, ...prev]);
  };

  const addInvoice = (inv: Omit<ClubInvoice, 'id'>) => {
    const newInv: ClubInvoice = { ...inv, id: `inv-${Date.now()}` };
    setInvoices((prev) => [newInv, ...prev]);
  };

  const payInvoice = (id: string) => {
    setInvoices((prev) =>
      prev.map((inv) => (inv.id === id ? { ...inv, status: 'paid' } : inv))
    );
  };

  const updateShipmentStatus = (id: string, status: Shipment['status']) => {
    setShipments((prev) =>
      prev.map((s) => (s.id === id ? { ...s, status } : s))
    );
  };

  const addShipment = (ship: Omit<Shipment, 'id' | 'createdAt'>) => {
    const newShip: Shipment = { ...ship, id: `ship-${Date.now()}`, createdAt: new Date().toISOString() };
    setShipments((prev) => [newShip, ...prev]);
  };

  const toggleAttendance = (
    courseId: string,
    childId: string,
    date: string,
    isPresent: boolean,
    notes?: string
  ) => {
    setAttendance((prev) => {
      const idx = prev.findIndex((a) => a.courseId === courseId && a.childId === childId && a.date === date);
      const child = childrenList.find((c) => c.id === childId);
      const childName = child ? `${child.firstName} ${child.lastName}` : 'Enfant';

      if (idx >= 0) {
        const updated = [...prev];
        updated[idx] = { ...updated[idx], isPresent, notes: notes ?? updated[idx].notes };
        return updated;
      } else {
        return [
          ...prev,
          {
            id: `att-${Date.now()}`,
            courseId,
            childId,
            childName,
            date,
            isPresent,
            notes,
          },
        ];
      }
    });
  };

  return (
    <AppContext.Provider
      value={{
        currentUser,
        setCurrentUser,
        switchRole,
        users: initialUsers,
        language,
        setLanguage,
        childrenList,
        selectedChildId,
        setSelectedChildId,
        selectedChild,
        addChild,
        updateChild,
        toggleCheckInStatus,
        transmissions,
        getChildTransmission,
        logMeal,
        logNap,
        logDiaper,
        logHealth,
        setChildMood,
        addMomentPhoto,
        togglePhotoLike,
        setParentMorningNote,
        setStaffDayNote,
        notifications,
        unreadNotificationsCount,
        markNotificationAsRead,
        clearAllNotifications,
        addCustomNotification,
        courses,
        addCourse,
        enrollments,
        enrollChild,
        updateEnrollmentStatus,
        schedules,
        addSchedule,
        events,
        addEvent,
        registerForEvent,
        expenses,
        addExpense,
        invoices,
        addInvoice,
        payInvoice,
        shipments,
        updateShipmentStatus,
        addShipment,
        attendance,
        toggleAttendance,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
