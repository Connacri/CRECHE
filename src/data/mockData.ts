import {
  Child,
  Course,
  Enrollment,
  SessionSchedule,
  ClubEvent,
  ClubExpense,
  ClubInvoice,
  Shipment,
  User,
  DailyTransmission,
  ParentNotification,
} from '../types';

export const initialUsers: User[] = [
  {
    id: 'u-parent-1',
    email: 'parent@creche.com',
    fullName: 'Marc Dupont',
    role: 'parent',
    phone: '+33 6 12 34 56 78',
    address: '14 Rue de la Paix, Paris',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    isActive: true,
    createdAt: '2025-01-15T09:00:00Z',
  },
  {
    id: 'u-school-1',
    email: 'direction@creche.com',
    fullName: 'Julie Moreau (Directrice)',
    role: 'school',
    schoolName: "Crèche & Académie Les Petits Oursons",
    phone: '+33 1 42 68 90 00',
    address: '28 Boulevard des Enfants, Paris',
    avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    isActive: true,
    createdAt: '2024-09-01T08:00:00Z',
  },
  {
    id: 'u-coach-1',
    email: 'coach.david@creche.com',
    fullName: 'David Renoir',
    role: 'coach',
    phone: '+33 6 88 99 00 11',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    isActive: true,
    createdAt: '2024-10-10T10:00:00Z',
  },
  {
    id: 'u-trans-1',
    email: 'logistique@creche.com',
    fullName: 'Yassine Benali (Transporteur)',
    role: 'transporteur',
    phone: '+33 6 45 67 89 10',
    avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    isActive: true,
    createdAt: '2024-11-05T11:00:00Z',
  },
  {
    id: 'u-fourn-1',
    email: 'fournisseur@creche.com',
    fullName: 'Fournisseur Repas Bio & Puériculture',
    role: 'fournisseur',
    phone: '+33 1 30 40 50 60',
    avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
    isActive: true,
    createdAt: '2024-11-01T12:00:00Z',
  },
  {
    id: 'u-admin-1',
    email: 'admin@creche.com',
    fullName: 'Super Administrateur',
    role: 'admin',
    phone: '+33 1 00 00 00 00',
    avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
    isActive: true,
    createdAt: '2024-01-01T00:00:00Z',
  }
];

export const initialChildren: Child[] = [
  {
    id: 'c-leo-1',
    parentId: 'u-parent-1',
    firstName: 'Léo',
    lastName: 'Dupont',
    dateOfBirth: '2022-04-14',
    gender: 'male',
    photoUrl: 'https://images.unsplash.com/photo-1543332164-6e82f355badc?w=150&auto=format&fit=crop&q=80',
    schoolGrade: 'Moyenne Section',
    groupName: 'Petits Oursons (2-3 ans)',
    medicalInfo: {
      allergies: ['Arachides'],
      medications: [],
      emergencyContact: 'Maman Sophie Dupont',
      emergencyPhone: '+33 6 98 76 54 32',
      bloodType: 'A+',
      additionalNotes: 'Porte des semelles, adore dessiner et écouter des histoires.'
    },
    checkInStatus: 'checked_in',
    lastCheckInTime: '08:32',
    qrCodeToken: 'CRECHE-BEAR-LEO-9923',
    createdAt: '2024-09-02T08:00:00Z',
    updatedAt: '2025-02-10T08:32:00Z',
    isActive: true,
  },
  {
    id: 'c-emma-2',
    parentId: 'u-parent-1',
    firstName: 'Emma',
    lastName: 'Dupont',
    dateOfBirth: '2024-01-18',
    gender: 'female',
    photoUrl: 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=150&auto=format&fit=crop&q=80',
    schoolGrade: 'Bébés & Trotteurs',
    groupName: 'Bébés Câlins (10-18 mois)',
    medicalInfo: {
      allergies: ['Lactose'],
      medications: ['Sérum physiologique après la sieste'],
      emergencyContact: 'Maman Sophie Dupont',
      emergencyPhone: '+33 6 98 76 54 32',
      bloodType: 'O+',
      additionalNotes: 'Doudou lapin bleu indispensable pour s’endormir.'
    },
    checkInStatus: 'checked_in',
    lastCheckInTime: '08:45',
    qrCodeToken: 'CRECHE-BEAR-EMMA-7741',
    createdAt: '2024-09-02T08:00:00Z',
    updatedAt: '2025-02-10T08:45:00Z',
    isActive: true,
  },
  {
    id: 'c-noah-3',
    parentId: 'u-parent-2',
    firstName: 'Noah',
    lastName: 'Martin',
    dateOfBirth: '2021-11-05',
    gender: 'male',
    photoUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150&auto=format&fit=crop&q=80',
    schoolGrade: 'Grande Section Club',
    groupName: 'Grands Explorateurs (3-4 ans)',
    medicalInfo: {
      allergies: [],
      medications: [],
      emergencyContact: 'Papa Julien Martin',
      emergencyPhone: '+33 6 11 22 33 44',
      bloodType: 'B+',
    },
    checkInStatus: 'checked_in',
    lastCheckInTime: '09:05',
    qrCodeToken: 'CRECHE-BEAR-NOAH-3301',
    createdAt: '2024-09-03T08:00:00Z',
    updatedAt: '2025-02-10T09:05:00Z',
    isActive: true,
  },
  {
    id: 'c-chloe-4',
    parentId: 'u-parent-3',
    firstName: 'Chloé',
    lastName: 'Bernard',
    dateOfBirth: '2023-06-20',
    gender: 'female',
    photoUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=150&auto=format&fit=crop&q=80',
    schoolGrade: 'Petite Section',
    groupName: 'Petits Oursons (2-3 ans)',
    medicalInfo: {
      allergies: ['Pollen de graminées'],
      medications: [],
      emergencyContact: 'Maman Claire Bernard',
      emergencyPhone: '+33 6 55 44 33 22',
      bloodType: 'AB+',
    },
    checkInStatus: 'picked_up',
    lastCheckInTime: '08:20',
    qrCodeToken: 'CRECHE-BEAR-CHLOE-1892',
    createdAt: '2024-09-04T08:00:00Z',
    updatedAt: '2025-02-10T16:30:00Z',
    isActive: true,
  }
];

const todayStr = new Date().toISOString().split('T')[0];

export const initialTransmissions: Record<string, DailyTransmission> = {
  'c-leo-1': {
    id: 'trans-leo-today',
    childId: 'c-leo-1',
    date: todayStr,
    mood: 'playful',
    parentMorningNote: "Léo s'est réveillé avec beaucoup d'énergie ce matin, il avait hâte de retrouver l'atelier peinture !",
    staffNotes: "Superbe journée ! Léo a été très attentif et a partagé ses jouets avec Noah.",
    meals: [
      {
        id: 'm-1',
        time: '11:45',
        mealType: 'lunch',
        title: 'Déjeuner Bio',
        menuDescription: 'Velouté de potimarron bio, écrasé de cabillaud à l’aneth, compote pomme-coing maison',
        quantity: 'all',
        notes: 'A fini toute son assiette en 20 minutes avec le sourire !'
      },
      {
        id: 'm-2',
        time: '15:45',
        mealType: 'snack',
        title: 'Goûter Fruité',
        menuDescription: 'Pain au lait bio, quartier de clémentine douce et yaourt nature brassé',
        quantity: 'good',
        notes: 'A adoré les quartiers de clémentine.'
      }
    ],
    naps: [
      {
        id: 'n-1',
        startTime: '13:00',
        endTime: '14:45',
        durationMinutes: 105,
        isSleeping: false,
        quality: 'calm',
        notes: 'Endormi dès la première berceuse. Réveil très doux et souriant.'
      }
    ],
    diapers: [
      {
        id: 'd-1',
        time: '10:15',
        type: 'clean',
        careApplied: 'Toilette du visage et change de routine'
      },
      {
        id: 'd-2',
        time: '14:50',
        type: 'wet',
        careApplied: 'Couche changée au réveil de sieste'
      }
    ],
    health: [
      {
        id: 'h-1',
        time: '11:15',
        temperature: 36.8,
        isFever: false,
        actionTaken: 'Contrôle de routine matinal normal'
      }
    ],
    photos: [
      {
        id: 'ph-1',
        url: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
        caption: '🎨 Atelier peinture avec les doigts : création de la fresque arc-en-ciel !',
        time: '10:30',
        likes: 4,
        hasLiked: true
      },
      {
        id: 'ph-2',
        url: 'https://images.unsplash.com/photo-1596495577886-d920f1fb7238?w=600&auto=format&fit=crop&q=80',
        caption: '🧸 Parcours de motricité : Léo a franchi le pont en équilibre comme un chef !',
        time: '15:15',
        likes: 2,
        hasLiked: false
      }
    ]
  },
  'c-emma-2': {
    id: 'trans-emma-today',
    childId: 'c-emma-2',
    date: todayStr,
    mood: 'calm',
    parentMorningNote: "Emma a un tout petit rhume, bien surveiller son nez après la sieste s'il vous plaît.",
    staffNotes: "Journée très paisible pour Emma. Elle a beaucoup aimé le tapis d'éveil sensoriel.",
    meals: [
      {
        id: 'm-3',
        time: '09:30',
        mealType: 'bottle',
        title: 'Biberon Matinal',
        menuDescription: 'Lait végétal sans lactose',
        bottleDrankMl: 210,
        bottlePlannedMl: 210,
        quantity: 'all',
        notes: 'Tout bu sans pause, rot fait rapidement.'
      },
      {
        id: 'm-4',
        time: '12:15',
        mealType: 'lunch',
        title: 'Petits Pots Bio',
        menuDescription: 'Purée douce de panais et dinde fermière',
        quantity: 'good',
        notes: 'Bien mangé, a laissé deux petites cuillères.'
      }
    ],
    naps: [
      {
        id: 'n-2',
        startTime: '13:15',
        isSleeping: true,
        quality: 'calm',
        notes: 'Sieste en cours dans le dortoir des bébés, avec son doudou lapin bleu.'
      }
    ],
    diapers: [
      {
        id: 'd-3',
        time: '09:45',
        type: 'wet',
        careApplied: 'Crème de change protectrice'
      },
      {
        id: 'd-4',
        time: '13:00',
        type: 'stool',
        stoolConsistency: 'normal',
        careApplied: 'Lavage du nez au sérum physiologique',
        needsRefillAlert: true
      }
    ],
    health: [
      {
        id: 'h-2',
        time: '10:00',
        temperature: 37.1,
        isFever: false,
        actionTaken: 'Nez mouché doucement'
      }
    ],
    photos: [
      {
        id: 'ph-3',
        url: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
        caption: '🌟 Découverte du tapis d’éveil musical : Emma rit aux éclats devant le miroir !',
        time: '11:00',
        likes: 5,
        hasLiked: true
      }
    ]
  }
};

export const initialNotifications: ParentNotification[] = [
  {
    id: 'notif-1',
    childId: 'c-leo-1',
    childName: 'Léo',
    type: 'meal',
    title: '🥣 Léo a tout mangé !',
    message: 'Déjeuner terminé : Léo a dévoré tout son velouté de potimarron et cabillaud bio avec appétit !',
    timestamp: '12:05',
    isRead: false,
    priority: 'normal',
    badgeIcon: '🥣'
  },
  {
    id: 'notif-2',
    childId: 'c-leo-1',
    childName: 'Léo',
    type: 'nap',
    title: '💤 Réveil de sieste',
    message: 'Léo s’est réveillé après 1h45 de sieste réparatrice. Il est en pleine forme pour le goûter !',
    timestamp: '14:48',
    isRead: false,
    priority: 'normal',
    badgeIcon: '💤'
  },
  {
    id: 'notif-3',
    childId: 'c-emma-2',
    childName: 'Emma',
    type: 'stock_alert',
    title: '🧷 Rappel Couches Emma',
    message: 'Attention : Il ne reste que 2 couches dans le casier d’Emma. Merci d’apporter un paquet demain.',
    timestamp: '13:05',
    isRead: false,
    priority: 'high',
    badgeIcon: '⚠️'
  },
  {
    id: 'notif-4',
    childId: 'c-leo-1',
    childName: 'Léo',
    type: 'photo',
    title: '📸 Nouvelle photo disponible',
    message: 'L’équipe des Petits Oursons a partagé une photo de l’atelier peinture de Léo !',
    timestamp: '10:35',
    isRead: true,
    priority: 'normal',
    badgeIcon: '🎨'
  },
  {
    id: 'notif-5',
    childId: 'c-leo-1',
    childName: 'Léo',
    type: 'checkin',
    title: '📍 Dépôt crèche confirmé',
    message: 'Léo a bien été accueilli par Julie à la crèche ce matin à 08h32.',
    timestamp: '08:33',
    isRead: true,
    priority: 'normal',
    badgeIcon: '🧸'
  }
];

export const initialCourses: Course[] = [
  {
    id: 'course-1',
    schoolId: 'u-school-1',
    title: 'Baby Gym & Motricité Globale',
    description: 'Parcours moteur adapté aux jeunes enfants pour développer équilibre, coordination et confiance corporelle en toute sécurité.',
    category: 'sports',
    season: 'schoolYear',
    level: 'beginner',
    pricingType: 'monthly',
    price: 45,
    currency: 'EUR',
    maxStudents: 12,
    enrolledCount: 9,
    coachId: 'u-coach-1',
    coachName: 'David Renoir',
    room: 'Salle Éveil & Motricité',
    imageUrl: 'https://images.unsplash.com/photo-1596495577886-d920f1fb7238?w=500&auto=format&fit=crop&q=80',
    status: 'active',
    scheduleDays: ['Mercredi', 'Samedi'],
    startTime: '10:00',
    endTime: '11:00',
    createdAt: '2024-09-01T00:00:00Z',
  },
  {
    id: 'course-2',
    schoolId: 'u-school-1',
    title: 'Éveil Musical & Sons du Monde',
    description: 'Découverte des instruments (percussions, métallophones), exploration des rythmes, chants traditionnels et comptines du monde.',
    category: 'music',
    season: 'schoolYear',
    level: 'beginner',
    pricingType: 'monthly',
    price: 40,
    currency: 'EUR',
    maxStudents: 10,
    enrolledCount: 8,
    coachId: 'u-coach-1',
    coachName: 'David Renoir',
    room: 'Atelier Harmonie',
    imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
    status: 'active',
    scheduleDays: ['Mercredi'],
    startTime: '14:30',
    endTime: '15:30',
    createdAt: '2024-09-01T00:00:00Z',
  },
  {
    id: 'course-3',
    schoolId: 'u-school-1',
    title: 'Anglais Ludique & Storytelling',
    description: 'Immersion en anglais par le jeu, les marionnettes, les chansons et des histoires captivantes animées par une animatrice bilingue.',
    category: 'languages',
    season: 'schoolYear',
    level: 'beginner',
    pricingType: 'monthly',
    price: 50,
    currency: 'EUR',
    maxStudents: 10,
    enrolledCount: 7,
    coachId: 'u-coach-2',
    coachName: 'Sarah Jenkins',
    room: 'Salle Londres',
    imageUrl: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=500&auto=format&fit=crop&q=80',
    status: 'active',
    scheduleDays: ['Mardi', 'Vendredi'],
    startTime: '16:45',
    endTime: '17:45',
    createdAt: '2024-09-01T00:00:00Z',
  },
  {
    id: 'course-4',
    schoolId: 'u-school-1',
    title: 'Arts Plastiques & Terres Créatives',
    description: 'Peinture végétale, modelage d’argile, collages de matières naturelles pour libérer la créativité et la motricité fine.',
    category: 'arts',
    season: 'schoolYear',
    level: 'beginner',
    pricingType: 'monthly',
    price: 42,
    currency: 'EUR',
    maxStudents: 8,
    enrolledCount: 6,
    coachId: 'u-coach-3',
    coachName: 'Camille Vasseur',
    room: 'Atelier Picasso',
    imageUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=500&auto=format&fit=crop&q=80',
    status: 'active',
    scheduleDays: ['Jeudi'],
    startTime: '15:00',
    endTime: '16:30',
    createdAt: '2024-09-01T00:00:00Z',
  }
];

export const initialEnrollments: Enrollment[] = [
  {
    id: 'enr-1',
    courseId: 'course-1',
    courseTitle: 'Baby Gym & Motricité Globale',
    childId: 'c-leo-1',
    childName: 'Léo Dupont',
    parentId: 'u-parent-1',
    parentName: 'Marc Dupont',
    schoolId: 'u-school-1',
    status: 'approved',
    paymentStatus: 'paid',
    price: 45,
    enrolledAt: '2024-09-10T10:00:00Z',
  },
  {
    id: 'enr-2',
    courseId: 'course-2',
    courseTitle: 'Éveil Musical & Sons du Monde',
    childId: 'c-leo-1',
    childName: 'Léo Dupont',
    parentId: 'u-parent-1',
    parentName: 'Marc Dupont',
    schoolId: 'u-school-1',
    status: 'approved',
    paymentStatus: 'paid',
    price: 40,
    enrolledAt: '2024-09-12T14:30:00Z',
  },
  {
    id: 'enr-3',
    courseId: 'course-3',
    courseTitle: 'Anglais Ludique & Storytelling',
    childId: 'c-leo-1',
    childName: 'Léo Dupont',
    parentId: 'u-parent-1',
    parentName: 'Marc Dupont',
    schoolId: 'u-school-1',
    status: 'pending',
    paymentStatus: 'pending',
    price: 50,
    enrolledAt: '2025-02-05T11:20:00Z',
    notes: 'Demande pour le créneau du mardi.'
  }
];

export const initialSchedules: SessionSchedule[] = [
  {
    id: 'sch-1',
    courseId: 'course-1',
    courseTitle: 'Baby Gym & Motricité',
    coachId: 'u-coach-1',
    coachName: 'David Renoir',
    dayOfWeek: 3,
    dayName: 'Mercredi',
    startTime: '10:00',
    endTime: '11:00',
    room: 'Salle Éveil & Motricité',
    capacity: 12,
    color: '#F59E0B',
  },
  {
    id: 'sch-2',
    courseId: 'course-2',
    courseTitle: 'Éveil Musical',
    coachId: 'u-coach-1',
    coachName: 'David Renoir',
    dayOfWeek: 3,
    dayName: 'Mercredi',
    startTime: '14:30',
    endTime: '15:30',
    room: 'Atelier Harmonie',
    capacity: 10,
    color: '#EC4899',
  },
  {
    id: 'sch-3',
    courseId: 'course-3',
    courseTitle: 'Anglais Ludique',
    coachId: 'u-coach-2',
    coachName: 'Sarah Jenkins',
    dayOfWeek: 2,
    dayName: 'Mardi',
    startTime: '16:45',
    endTime: '17:45',
    room: 'Salle Londres',
    capacity: 10,
    color: '#8B5CF6',
  },
  {
    id: 'sch-4',
    courseId: 'course-4',
    courseTitle: 'Arts Plastiques',
    coachId: 'u-coach-3',
    coachName: 'Camille Vasseur',
    dayOfWeek: 4,
    dayName: 'Jeudi',
    startTime: '15:00',
    endTime: '16:30',
    room: 'Atelier Picasso',
    capacity: 8,
    color: '#10B981',
  }
];

export const initialEvents: ClubEvent[] = [
  {
    id: 'evt-1',
    title: 'Carnaval & Fête du Printemps des Oursons',
    description: 'Défilé déguisé, spectacle de marionnettes géantes, goûter bio festif et ateliers maquillage sécurisé doux.',
    eventType: 'gala',
    status: 'registrationOpen',
    startDate: '2025-03-21 15:00',
    endDate: '2025-03-21 18:30',
    location: 'Jardin & Cour d’Honneur de la Crèche',
    maxParticipants: 40,
    registeredCount: 28,
    price: 10,
    imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&auto=format&fit=crop&q=80',
  },
  {
    id: 'evt-2',
    title: 'Portes Ouvertes & Ateliers Découverte Parents-Bébés',
    description: 'Rencontre avec les éducatrices et les coaches sportifs, séances d’initiation gratuites pour les frères et sœurs.',
    eventType: 'porteOuverte',
    status: 'registrationOpen',
    startDate: '2025-04-12 10:00',
    endDate: '2025-04-12 16:00',
    location: 'Ensemble des locaux Crèche & Club',
    maxParticipants: 60,
    registeredCount: 45,
    price: 0,
    imageUrl: 'https://images.unsplash.com/photo-1577896851231-70ef18881754?w=600&auto=format&fit=crop&q=80',
  }
];

export const initialExpenses: ClubExpense[] = [
  {
    id: 'exp-1',
    title: 'Renouvellement Tapis Motricité & Doudous Hypoallergéniques',
    category: 'equipment',
    amount: 680,
    date: '2025-02-01',
    receiptNumber: 'FAC-MAT-2025-04',
    notes: 'Mousse haute densité norme puériculture NF.'
  },
  {
    id: 'exp-2',
    title: 'Approvisionnement Repas Bio & Fruits Doux de Saison',
    category: 'activities',
    amount: 1420,
    date: '2025-02-05',
    receiptNumber: 'BIO-2025-029',
    notes: 'Fournisseur local circuits courts certifié Ecocert.'
  }
];

export const initialInvoices: ClubInvoice[] = [
  {
    id: 'inv-1',
    invoiceNumber: 'INV-2025-001',
    parentId: 'u-parent-1',
    parentName: 'Marc Dupont',
    childName: 'Léo Dupont',
    courseTitle: 'Baby Gym & Motricité (Février)',
    amount: 45,
    issueDate: '2025-02-01',
    dueDate: '2025-02-15',
    status: 'paid',
  },
  {
    id: 'inv-2',
    invoiceNumber: 'INV-2025-002',
    parentId: 'u-parent-1',
    parentName: 'Marc Dupont',
    childName: 'Léo Dupont',
    courseTitle: 'Éveil Musical (Février)',
    amount: 40,
    issueDate: '2025-02-01',
    dueDate: '2025-02-15',
    status: 'paid',
  },
  {
    id: 'inv-3',
    invoiceNumber: 'INV-2025-003',
    parentId: 'u-parent-1',
    parentName: 'Marc Dupont',
    childName: 'Emma Dupont',
    courseTitle: 'Frais de Garde Mensuel Crèche (Février)',
    amount: 490,
    issueDate: '2025-02-01',
    dueDate: '2025-02-28',
    status: 'pending',
  }
];

export const initialShipments: Shipment[] = [
  {
    id: 'ship-1',
    trackingNumber: 'LOG-CR-99210',
    senderName: 'BioTerroir Maraîchage & Repas',
    receiverName: 'Cuisine Crèche Les Petits Oursons',
    transporteurName: 'Yassine Benali (Logistique Express)',
    status: 'delivered',
    originAddress: 'Ferme de Saclay, Essonne',
    destinationAddress: '28 Boulevard des Enfants, Paris',
    weight: 22.0,
    estimatedDelivery: 'Aujourd’hui 11h30',
    notes: 'Paniers de potimarrons, compotes et légumes bio.',
    createdAt: '2025-02-10T06:30:00Z',
  },
  {
    id: 'ship-2',
    trackingNumber: 'LOG-CR-99342',
    senderName: 'Centrale Puériculture & Soins Doux',
    receiverName: 'Crèche Les Petits Oursons',
    transporteurName: 'Yassine Benali (Logistique Express)',
    status: 'in_transit',
    originAddress: 'Entrepôt Rungis',
    destinationAddress: '28 Boulevard des Enfants, Paris',
    weight: 35.5,
    estimatedDelivery: 'Aujourd’hui 14h00',
    notes: 'Couches écologiques, sérum physiologique et gants doux.',
    createdAt: '2025-02-10T08:00:00Z',
  }
];
