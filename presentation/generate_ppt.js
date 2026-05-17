const PptxGenJS = require("pptxgenjs");
const path = require("path");

// Initialize Presentation
const pptx = new PptxGenJS();
pptx.layout = "LAYOUT_16x9";

// Define Color Scheme (Hex without '#')
const COLORS = {
  bgDark: "0F172A",     // Slate 900
  bgLight: "F8FAFC",    // Slate 50
  textDark: "1E293B",   // Slate 800
  textLight: "F8FAFC",  // Slate 50
  accentBlue: "0EA5E9", // Sky 500
  accentTeal: "0D9488", // Teal 600
  grayMuted: "64748B",  // Slate 500
  cardBg: "E2E8F0"      // Slate 200
};

// Helper: Add Standard Dark Slide (Title, Conclusion)
function addDarkSlide(title, subtitle, extraContent = null) {
  const slide = pptx.addSlide();
  slide.background = { fill: COLORS.bgDark };
  
  // Decorative Accent Line
  slide.addShape("rect", { x: 0.6, y: 0.4, w: 1.5, h: 0.08, fill: { color: COLORS.accentBlue } });
  
  return slide;
}

// Helper: Add Standard Light Slide with Header
function addLightSlide(title, category = "CAMPUS APPOINTMENT BOOKING SYSTEM") {
  const slide = pptx.addSlide();
  slide.background = { fill: COLORS.bgLight };
  
  // Small Category Header
  slide.addText(category.toUpperCase(), {
    x: 0.6,
    y: 0.3,
    w: 8.8,
    h: 0.3,
    fontSize: 10,
    bold: true,
    color: COLORS.accentBlue,
    fontFace: "Segoe UI"
  });
  
  // Slide Title
  slide.addText(title, {
    x: 0.6,
    y: 0.6,
    w: 8.8,
    h: 0.6,
    fontSize: 24,
    bold: true,
    color: COLORS.bgDark,
    fontFace: "Segoe UI"
  });
  
  // Horizontal Divider
  slide.addShape("rect", { x: 0.6, y: 1.1, w: 8.8, h: 0.02, fill: { color: "CBD5E1" } });
  
  return slide;
}

// ==========================================
// SLIDE 1: Title Slide (Dark Theme)
// ==========================================
const s1 = pptx.addSlide();
s1.background = { fill: COLORS.bgDark };

// Decorative elements
s1.addShape("rect", { x: 0, y: 0, w: 0.3, h: 5.625, fill: { color: COLORS.accentBlue } });
s1.addShape("rect", { x: 0.3, y: 0, w: 0.1, h: 5.625, fill: { color: COLORS.accentTeal } });

s1.addText("UNIVERSITY OF GONDAR • COLLEGE OF INFORMATICS", {
  x: 0.8,
  y: 0.8,
  w: 8.5,
  h: 0.4,
  fontSize: 12,
  bold: true,
  color: COLORS.accentBlue,
  fontFace: "Segoe UI",
  charSpacing: 2
});

s1.addText("CAMPUS APPOINTMENT\nBOOKING SYSTEM", {
  x: 0.8,
  y: 1.3,
  w: 8.5,
  h: 1.4,
  fontSize: 40,
  bold: true,
  color: COLORS.textLight,
  fontFace: "Segoe UI",
  lineSpacing: 46
});

s1.addText("A Cross-Platform Mobile & Web Solution for Higher Education Scheduling", {
  x: 0.8,
  y: 2.8,
  w: 8.5,
  h: 0.5,
  fontSize: 16,
  italic: true,
  color: COLORS.grayMuted,
  fontFace: "Segoe UI"
});

// Footer / Submission Box
s1.addShape("rect", { x: 0.8, y: 3.7, w: 8.4, h: 1.3, fill: "1E293B", line: { color: "334155", width: 1 } });

s1.addText("Course Project: Mobile Application Development (CoIt-3112)\nSubmitted by: Department of Information Technology (IT) Project Team\nDate of Submission: May 2026", {
  x: 1.0,
  y: 3.8,
  w: 8.0,
  h: 1.1,
  fontSize: 11,
  color: COLORS.textLight,
  fontFace: "Segoe UI",
  lineSpacing: 22
});


// ==========================================
// SLIDE 2: Problem Statement (Light Theme)
// ==========================================
const s2 = addLightSlide("The Institutional Bottleneck", "The Scheduling Crisis");

// Left Column: Bullet Points
const s2LeftText = 
  "• Manual, Paper-Based Workflows:\n  Traditional office queues waste valuable study hours standing outside offices.\n\n" +
  "• Zero Real-Time Availability:\n  Students lack visibility into whether service providers are out-of-office, in a meeting, or free.\n\n" +
  "• Document Fragmentation & Loss:\n  Supporting files (medical certificates, registration forms) get misplaced in chaotic email chains.\n\n" +
  "• Telehealth & Virtual Consultations Gap:\n  Distance students must manually coordinate virtual meetings, leading to disconnected experiences.";

s2.addText(s2LeftText, {
  x: 0.6,
  y: 1.4,
  w: 4.8,
  h: 3.7,
  fontSize: 12,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 18
});

// Right Column: Legacy vs Modern Card
s2.addShape("rect", { x: 5.7, y: 1.4, w: 3.7, h: 3.6, fill: "F1F5F9", line: { color: "E2E8F0", width: 1 } });
s2.addText("THE BOTTLENECK", { x: 6.0, y: 1.7, w: 3.1, h: 0.3, fontSize: 13, bold: true, color: "EF4444", fontFace: "Segoe UI" });

const bottleneckDetails = 
  "1. Chaotic Queues\n" +
  "2. Blind Bookings\n" +
  "3. Missing Documents\n" +
  "4. Fractured Communication\n\n" +
  "Result: High institutional friction and reduced student academic satisfaction.";

s2.addText(bottleneckDetails, {
  x: 6.0,
  y: 2.1,
  w: 3.1,
  h: 2.6,
  fontSize: 12,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 18
});


// ==========================================
// SLIDE 3: Project Vision & Objectives (Light Theme)
// ==========================================
const s3 = addLightSlide("Core Vision & Objectives", "Project Objectives");

const s3Text = 
  "• Unified Digital Scheduler:\n  Bridge the gap between students and administrative/clinical departments through an intuitive, centralized portal.\n\n" +
  "• Real-Time Reactive Synchronization:\n  Enable immediate booking confirmation, cancellation reason tracking, and instant role-based dashboard updates.\n\n" +
  "• Robust State Preservation (Routing Cache):\n  Implement background routing cache models so user sessions survive unintended web browser refreshes cleanly.\n\n" +
  "• Attendance & Validation Automation:\n  Leverage local secure QR code ticket generation and mobile scanning for quick, authenticated attendance tracking.";

s3.addText(s3Text, {
  x: 0.6,
  y: 1.4,
  w: 8.8,
  h: 3.6,
  fontSize: 13,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 20
});


// ==========================================
// SLIDE 4: Multi-Role System Architecture (Light Theme)
// ==========================================
const s4 = addLightSlide("Specialized Role Workflows", "System Actors");

// Three column cards
const roles = [
  {
    title: "STUDENT",
    color: "0EA5E9",
    x: 0.6,
    text: "• Search & Filter Departments\n• Select Available Time Slots\n• Upload Support Attachments\n• Real-Time Text Messaging\n• Check-in QR Codes\n• Direct Jitsi Telehealth Join"
  },
  {
    title: "SERVICE PROVIDER",
    color: "0D9488",
    x: 3.7,
    text: "• incoming Booking Pipeline\n• Single-Click Confirm/Decline\n• Log Decline Explanations\n• QR Attendance Scanner\n• Global Availability Switch\n• In-App Jitsi Video Rooms"
  },
  {
    title: "SYSTEM ADMIN",
    color: "6366F1",
    x: 6.8,
    text: "• Department Entity Setup\n• User Role Elevation Console\n• Multi-Department Auditing\n• Service Category Tuning\n• Session Transaction Logs\n• General Analytics Metrics"
  }
];

roles.forEach(role => {
  // Card background
  s4.addShape("rect", { x: role.x, y: 1.4, w: 2.9, h: 3.6, fill: "FFFFFF", line: { color: "E2E8F0", width: 2 } });
  
  // Card header band
  s4.addShape("rect", { x: role.x, y: 1.4, w: 2.9, h: 0.5, fill: role.color });
  s4.addText(role.title, {
    x: role.x + 0.1,
    y: 1.5,
    w: 2.7,
    h: 0.3,
    fontSize: 12,
    bold: true,
    color: "FFFFFF",
    align: "center",
    fontFace: "Segoe UI"
  });
  
  // Card body text
  s4.addText(role.text, {
    x: role.x + 0.15,
    y: 2.1,
    w: 2.6,
    h: 2.8,
    fontSize: 11,
    color: COLORS.textDark,
    fontFace: "Segoe UI",
    lineSpacing: 16
  });
});


// ==========================================
// SLIDE 5: Technical Stack (Light Theme)
// ==========================================
const s5 = addLightSlide("High-Level System Architecture", "Tech Stack");

const s5Left = 
  "• Front-End (Client Layer):\n  Cross-platform app built natively with Flutter, using MultiProvider state controllers and SharedPreferences local caching.\n\n" +
  "• Transport Layer (APIs & Real-time):\n  HTTP REST APIs via Axios/HTTP clients and WebSockets via Socket.IO for immediate, timezone-aware chats.\n\n" +
  "• Back-End (Service Layer):\n  Node.js and Express REST engines secured by JSON Web Token (JWT) authenticators.\n\n" +
  "• Database (Persistence Layer):\n  Scalable, cloud-hosted MongoDB Atlas Cluster supporting schema-based collection configurations.";

s5.addText(s5Left, {
  x: 0.6,
  y: 1.4,
  w: 4.8,
  h: 3.7,
  fontSize: 12,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 18
});

// Diagram box
s5.addShape("rect", { x: 5.7, y: 1.4, w: 3.7, h: 3.6, fill: "0F172A", line: { color: "1E293B", width: 1 } });
s5.addText("DATA PIPELINE & ARCHITECTURE", {
  x: 5.9,
  y: 1.6,
  w: 3.3,
  h: 0.3,
  fontSize: 11,
  bold: true,
  color: COLORS.accentBlue,
  fontFace: "Segoe UI"
});

const diagramFlow = 
  " [ Flutter Client UI ] \n" +
  "          │  ▲ (State Controllers)\n" +
  "          ▼  │\n" +
  " [ REST APIs & WebSockets ] \n" +
  "          │  ▲ (JWT Secured Route)\n" +
  "          ▼  │\n" +
  " [ Node.js Express Server ] \n" +
  "          │  ▲ (Mongoose schemas)\n" +
  "          ▼  │\n" +
  " [ MongoDB Atlas (Cloud) ]";

s5.addText(diagramFlow, {
  x: 5.9,
  y: 2.0,
  w: 3.3,
  h: 2.8,
  fontSize: 11,
  color: "94A3B8",
  fontFace: "Courier New",
  lineSpacing: 12
});


// ==========================================
// SLIDE 6: Technical Highlights & Code Secrets (Light Theme)
// ==========================================
const s6 = addLightSlide("Core Engineering Enhancements", "Technical Innovations");

const s6LeftText = 
  "1. Routing State Preservation (Web Refresh Recovery):\n" +
  "   • Challenge: Organic web browser page refreshes normally wipe out current screen routes.\n" +
  "   • Solution: Integrated SharedPreferences state interceptor in all core dashboard screen views, restoring the user's active screen (e.g. `my_appointments` vs `manage_appointments`) upon reload.\n\n" +
  "2. Conditional Jitsi Meet Video Compilation:\n" +
  "   • Challenge: Native Jitsi video SDKs cause build failures and compiler conflicts on Flutter web platforms.\n" +
  "   • Solution: Built a Conditional Stub Architecture wrapper using dynamic platform queries (kIsWeb) to load native mobile controllers for apps, falling back to seamless native browser stubs (`js.context.callMethod('open')`) for web clients.";

s6.addText(s6LeftText, {
  x: 0.6,
  y: 1.4,
  w: 8.8,
  h: 3.7,
  fontSize: 12,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 18
});


// ==========================================
// SLIDE 7: Client Interface In Action (Light Theme)
// ==========================================
const s7 = addLightSlide("Student Consultation & Jitsi Portals", "Student & Video Interface");

// Left Column: Student view with call button
s7.addText("My Appointments Portal (Student View)\n• Displays a chronological list of student appointments with colored status flags.\n• In-app deep integration with virtual meeting rooms.\n• One-tap 'JOIN CALL' action triggers virtual meeting launchers.", {
  x: 0.6,
  y: 1.4,
  w: 4.2,
  h: 1.5,
  fontSize: 11,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 15
});

s7.addImage({
  path: "assets/media__1779010092137.png",
  x: 0.6,
  y: 3.0,
  w: 4.2,
  h: 2.1,
  sizing: { type: "contain" }
});

// Right Column: Pending Details
s7.addText("Detail Dashboard (Staff/Advisor View)\n• Granular overview of incoming appointment requests.\n• Lists download links to file attachments uploaded by students.\n• Instant actions: green-lit 'Approve' and red-lit 'Reject'.", {
  x: 5.2,
  y: 1.4,
  w: 4.2,
  h: 1.5,
  fontSize: 11,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 15
});

s7.addImage({
  path: "assets/media__1779012902167.png",
  x: 5.2,
  y: 3.0,
  w: 4.2,
  h: 2.1,
  sizing: { type: "contain" }
});


// ==========================================
// SLIDE 8: Service & Staff Admin Screens (Light Theme)
// ==========================================
const s8 = addLightSlide("Service & Staff Administration Controls", "Staff Dashboard");

// Left: Manage Services Screen
s8.addText("Service Category Configurator\n• Staff/Admin portal to add and manage different services.\n• Set customizable service durations (e.g. 30 mins) and link to respective departmental heads.\n• Clean grid edit interfaces built using Material Design cards.", {
  x: 0.6,
  y: 1.4,
  w: 4.2,
  h: 1.5,
  fontSize: 11,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 15
});

s8.addImage({
  path: "assets/media__1779003383391.png",
  x: 0.6,
  y: 3.0,
  w: 4.2,
  h: 2.1,
  sizing: { type: "contain" }
});

// Right: Manage Appointments
s8.addText("Administrative Booking Pipelines\n• Comprehensive timeline dashboard listing all student requests.\n• Displays dynamic cancellation notices and approved virtual schedules.\n• Role-filtered metrics track institutional workloads.", {
  x: 5.2,
  y: 1.4,
  w: 4.2,
  h: 1.5,
  fontSize: 11,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 15
});

s8.addImage({
  path: "assets/media__1779003259407.png",
  x: 5.2,
  y: 3.0,
  w: 4.2,
  h: 2.1,
  sizing: { type: "contain" }
});


// ==========================================
// SLIDE 9: System Deployment & Migration (Light Theme)
// ==========================================
const s9 = addLightSlide("Seamless System Deployment", "Deployment & Migration");

const s9Left = 
  "• Live API Cloud Deployments:\n  Express.js server deployed onto Render hosting servers with static root redirect mappings for web clients.\n\n" +
  "• Cloud Database Orchestration:\n  MongoDB local databases successfully migrated to secure MongoDB Atlas cloud instances, configured with role-based accessibility filters.\n\n" +
  "• Client-Side Executable Compilations:\n  • Web: Bundles generated via `flutter build web` served automatically as static public middleware assets.\n  • Android: Release packages (`app-release.apk`) successfully compiled ready for student downloads.";

s9.addText(s9Left, {
  x: 0.6,
  y: 1.4,
  w: 4.8,
  h: 3.7,
  fontSize: 12,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 18
});

// Right: Quick Migration Box
s9.addShape("rect", { x: 5.7, y: 1.4, w: 3.7, h: 3.6, fill: "F1F5F9", line: { color: "CBD5E1", width: 1 } });
s9.addText("DEPLOYMENT MATRIX", { x: 6.0, y: 1.7, w: 3.1, h: 0.3, fontSize: 13, bold: true, color: COLORS.accentTeal, fontFace: "Segoe UI" });

const deploymentTable = 
  "■ BACKEND STACK:\n  • Hosting: Render Cloud\n  • DB: MongoDB Atlas (Live)\n  • Auth: Salter BCrypt / JWT\n\n" +
  "■ FRONTEND STACK:\n  • Framework: Flutter 3.x\n  • Deploy Web: Built-in middleware\n  • Deploy Android: Release APK";

s9.addText(deploymentTable, {
  x: 6.0,
  y: 2.1,
  w: 3.1,
  h: 2.6,
  fontSize: 11,
  color: COLORS.textDark,
  fontFace: "Segoe UI",
  lineSpacing: 16
});


// ==========================================
// SLIDE 10: Conclusion & Future Roadmap (Dark Theme)
// ==========================================
const s10 = pptx.addSlide();
s10.background = { fill: COLORS.bgDark };

s10.addShape("rect", { x: 0, y: 0, w: 0.3, h: 5.625, fill: { color: COLORS.accentTeal } });
s10.addShape("rect", { x: 0.3, y: 0, w: 0.1, h: 5.625, fill: { color: COLORS.accentBlue } });

s10.addText("CONCLUSION & FUTURE ROADMAP", {
  x: 0.8,
  y: 0.6,
  w: 8.5,
  h: 0.4,
  fontSize: 12,
  bold: true,
  color: COLORS.accentTeal,
  fontFace: "Segoe UI",
  charSpacing: 2
});

s10.addText("A Seamless Future for Campus Scheduling", {
  x: 0.8,
  y: 1.0,
  w: 8.5,
  h: 0.6,
  fontSize: 26,
  bold: true,
  color: COLORS.textLight,
  fontFace: "Segoe UI"
});

// Left Column: Key Achievements
s10.addText("KEY ACHIEVEMENTS\n• Successfully unified student/staff calendars into a responsive, real-time dashboard.\n• Overcame web browser reload routing resets using persistence caches.\n• Eliminated mobile-web compilation conflicts through conditional stub layers.", {
  x: 0.8,
  y: 1.8,
  w: 4.0,
  h: 3.2,
  fontSize: 12,
  color: "CBD5E1",
  fontFace: "Segoe UI",
  lineSpacing: 18
});

// Right Column: Future Roadmap
s10.addText("FUTURE ENHANCEMENTS\n• AI-Driven Auto-Scheduling: Intelligently matching students with optimal advisor time slots.\n• Push Notifications: Automatic WhatsApp & SMS alert chains (via Twilio).\n• Advanced Office Analytics: Admin reports mapping department load metrics over semesters.", {
  x: 5.2,
  y: 1.8,
  w: 4.0,
  h: 3.2,
  fontSize: 12,
  color: "CBD5E1",
  fontFace: "Segoe UI",
  lineSpacing: 18
});


// ==========================================
// SAVE PRESENTATION
// ==========================================
const filename = "Campus_Appointment_Booking_System_Presentation.pptx";
pptx.writeFile({ fileName: filename })
  .then(savedName => {
    console.log(`SUCCESS: PowerPoint Presentation successfully saved to: ${savedName}`);
  })
  .catch(err => {
    console.error(`ERROR: Failed to save PowerPoint presentation: ${err}`);
  });
