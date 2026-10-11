export type UserRole =
  | 'admin'
  | 'parent'
  | 'coach'
  | 'school'
  | 'transporteur'
  | 'fournisseur'
  | 'user'
  | 'autres';

export type Language = 'fr' | 'en' | 'ar';

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: UserRole;
  phone?: string;
  avatarUrl?: string;
  schoolName?: string;
  address?: string;
  isActive: boolean;
  createdAt: string;
}

export type ChildGender = 'male' | 'female';

export interface MedicalInfo {
  allergies: string[];
  medications: string[];
  emergencyContact: string;
  emergencyPhone: string;
  bloodType: string;
  additionalNotes?: string;
}

export type EatenQuantity = 'all' | 'good' | 'little' | 'none';

export interface MealLog {
  id: string;
  time: string;
  mealType: 'breakfast' | 'lunch' | 'snack' | 'bottle';
  title: string;
  menuDescription: string;
  quantity: EatenQuantity;
  bottleDrankMl?: number;
  bottlePlannedMl?: number;
  notes?: string;
}

export interface NapLog {
  id: string;
  startTime: string;
  endTime?: string;
  durationMinutes?: number;
  isSleeping: boolean;
  quality: 'calm' | 'normal' | 'agitated';
  notes?: string;
}

export interface DiaperLog {
  id: string;
  time: string;
  type: 'wet' | 'stool' | 'both' | 'clean';
  stoolConsistency?: 'normal' | 'soft' | 'liquid';
  careApplied?: string; // e.g. "Crème de change", "Lavage sérum phy"
  needsRefillAlert?: boolean; // Needs to bring diapers tomorrow
}

export interface HealthLog {
  id: string;
  time: string;
  temperature: number;
  isFever: boolean; // > 38°C
  symptoms?: string;
  actionTaken?: string; // e.g. "Doliprane 150mg donné après accord parent"
}

export type ChildMood = 'happy' | 'playful' | 'calm' | 'tired' | 'crying';

export interface MomentPhoto {
  id: string;
  url: string;
  caption: string;
  time: string;
  likes: number;
  hasLiked?: boolean;
}

export interface DailyTransmission {
  id: string;
  childId: string;
  date: string; // YYYY-MM-DD
  meals: MealLog[];
  naps: NapLog[];
  diapers: DiaperLog[];
  health: HealthLog[];
  mood: ChildMood;
  photos: MomentPhoto[];
  staffNotes?: string;
  parentMorningNote?: string; // Note left by parent in the morning
}

export interface Child {
  id: string;
  parentId: string;
  firstName: string;
  lastName: string;
  dateOfBirth: string; // ISO date
  gender: ChildGender;
  photoUrl?: string;
  schoolGrade?: string;
  groupName: string; // e.g. "Petits Oursons", "Grands Explorateurs"
  medicalInfo: MedicalInfo;
  checkInStatus: 'at_home' | 'checked_in' | 'picked_up';
  lastCheckInTime?: string;
  qrCodeToken: string;
  createdAt: string;
  updatedAt: string;
  isActive: boolean;
}

export type NotificationType =
  | 'meal'
  | 'nap'
  | 'fever'
  | 'diaper'
  | 'checkin'
  | 'photo'
  | 'stock_alert'
  | 'message'
  | 'general';

export interface ParentNotification {
  id: string;
  childId?: string;
  childName?: string;
  type: NotificationType;
  title: string;
  message: string;
  timestamp: string;
  isRead: boolean;
  priority: 'normal' | 'high' | 'urgent';
  badgeIcon?: string;
}

export type CourseCategory =
  | 'mathematics'
  | 'sciences'
  | 'languages'
  | 'technology'
  | 'computerScience'
  | 'arts'
  | 'music'
  | 'sports'
  | 'health'
  | 'cooking'
  | 'crafts'
  | 'tutoring'
  | 'other';

export type CourseSeason =
  | 'spring'
  | 'summer'
  | 'fall'
  | 'winter'
  | 'schoolYear'
  | 'yearRound';

export type CourseLevel = 'beginner' | 'intermediate' | 'advanced';
export type CoursePricingType = 'hourly' | 'session' | 'monthly' | 'quarterly' | 'yearly';
export type CourseStatus = 'draft' | 'active' | 'completed' | 'cancelled';

export interface Course {
  id: string;
  schoolId: string;
  title: string;
  description: string;
  category: CourseCategory;
  season: CourseSeason;
  level: CourseLevel;
  pricingType: CoursePricingType;
  price: number;
  currency: string;
  maxStudents: number;
  enrolledCount: number;
  coachId: string;
  coachName: string;
  room?: string;
  imageUrl?: string;
  status: CourseStatus;
  scheduleDays: string[];
  startTime: string;
  endTime: string;
  createdAt: string;
}

export type EnrollmentStatus = 'pending' | 'approved' | 'rejected' | 'cancelled' | 'completed';
export type PaymentStatus = 'pending' | 'partial' | 'paid' | 'refunded';

export interface Enrollment {
  id: string;
  courseId: string;
  courseTitle: string;
  childId: string;
  childName: string;
  parentId: string;
  parentName: string;
  schoolId: string;
  status: EnrollmentStatus;
  paymentStatus: PaymentStatus;
  price: number;
  enrolledAt: string;
  notes?: string;
}

export interface AttendanceRecord {
  id: string;
  courseId: string;
  date: string;
  childId: string;
  childName: string;
  isPresent: boolean;
  notes?: string;
}

export interface SessionSchedule {
  id: string;
  courseId: string;
  courseTitle: string;
  coachId: string;
  coachName: string;
  dayOfWeek: number;
  dayName: string;
  startTime: string;
  endTime: string;
  room: string;
  capacity: number;
  color: string;
}

export type EventType =
  | 'competition'
  | 'stage'
  | 'porteOuverte'
  | 'reunion'
  | 'examen'
  | 'tournoi'
  | 'gala'
  | 'formation'
  | 'social'
  | 'autre';

export type EventStatus =
  | 'draft'
  | 'published'
  | 'registrationOpen'
  | 'registrationClosed'
  | 'ongoing'
  | 'completed'
  | 'cancelled';

export interface ClubEvent {
  id: string;
  title: string;
  description: string;
  eventType: EventType;
  status: EventStatus;
  startDate: string;
  endDate: string;
  location: string;
  maxParticipants: number;
  registeredCount: number;
  price: number;
  imageUrl?: string;
}

export interface ClubExpense {
  id: string;
  title: string;
  category: 'equipment' | 'maintenance' | 'salary' | 'utilities' | 'activities' | 'other';
  amount: number;
  date: string;
  notes?: string;
  receiptNumber?: string;
}

export interface ClubInvoice {
  id: string;
  invoiceNumber: string;
  parentId: string;
  parentName: string;
  childName: string;
  courseTitle: string;
  amount: number;
  issueDate: string;
  dueDate: string;
  status: 'paid' | 'pending' | 'overdue';
}

export interface Shipment {
  id: string;
  trackingNumber: string;
  senderName: string;
  receiverName: string;
  transporteurName: string;
  status: 'pending' | 'in_transit' | 'delivered' | 'cancelled';
  originAddress: string;
  destinationAddress: string;
  weight: number;
  estimatedDelivery: string;
  notes?: string;
  createdAt: string;
}
