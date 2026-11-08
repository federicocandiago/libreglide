// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class L10nEs extends L10n {
  L10nEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'libreGLIDE';

  @override
  String get suggestionsTitle => 'Para ti ahora';

  @override
  String get learningHint =>
      'libreGLIDE está aprendiendo tus hábitos: las apps sugeridas aparecerán tras unas cuantas aperturas.';

  @override
  String get favoritesEmpty =>
      'Mantén pulsada una app para añadirla a favoritos';

  @override
  String contextChip(Object slot, Object dayType) {
    return '$slot · $dayType';
  }

  @override
  String get notDefaultBanner => 'libreGLIDE aún no es tu app de inicio';

  @override
  String get setAction => 'Configurar';

  @override
  String get slotWakeUp => 'Despertar';

  @override
  String get slotMorning => 'Mañana';

  @override
  String get slotLunch => 'Comida';

  @override
  String get slotAfternoon => 'Tarde';

  @override
  String get slotEvening => 'Noche';

  @override
  String get slotNight => 'Madrugada';

  @override
  String get dayWorkday => 'laborable';

  @override
  String get dayHoliday => 'festivo';

  @override
  String get pageHome => 'Inicio';

  @override
  String get pageCollections => 'Collections';

  @override
  String get pageAllApps => 'Todas las apps';

  @override
  String appCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get pinCategory => 'Fijar arriba';

  @override
  String get unpinCategory => 'Dejar de fijar';

  @override
  String get hideCategory => 'Ocultar categoría';

  @override
  String get categoryHidden =>
      'Categoría oculta. Puedes restaurarla en los ajustes.';

  @override
  String get undo => 'Deshacer';

  @override
  String get noCollections => 'No hay apps que mostrar';

  @override
  String get catSocial => 'Social';

  @override
  String get catMessaging => 'Mensajes y llamadas';

  @override
  String get catMusic => 'Música y audio';

  @override
  String get catVideo => 'Vídeo';

  @override
  String get catPhoto => 'Fotos';

  @override
  String get catNews => 'Noticias';

  @override
  String get catMaps => 'Mapas y viajes';

  @override
  String get catProductivity => 'Productividad';

  @override
  String get catWork => 'Trabajo';

  @override
  String get catEducation => 'Estudio';

  @override
  String get catFinance => 'Finanzas';

  @override
  String get catShopping => 'Compras';

  @override
  String get catFood => 'Comida';

  @override
  String get catHealth => 'Salud y deporte';

  @override
  String get catGames => 'Juegos';

  @override
  String get catTools => 'Herramientas';

  @override
  String get catSystem => 'Sistema';

  @override
  String get catOther => 'Otros';

  @override
  String get searchHint => 'Buscar apps';

  @override
  String get noResults => 'No se encontraron apps';

  @override
  String get bestMatch => 'Mejor resultado';

  @override
  String get otherResults => 'Otros resultados';

  @override
  String searchWeb(String query) {
    return 'Buscar «$query» en la web';
  }

  @override
  String get layoutGrid => 'Cuadrícula';

  @override
  String get layoutList => 'Lista';

  @override
  String get addFavorite => 'Añadir a favoritos';

  @override
  String get removeFavorite => 'Quitar de favoritos';

  @override
  String favoritesFull(int max) {
    return 'Puedes tener hasta $max favoritos';
  }

  @override
  String get changeCategory => 'Cambiar categoría';

  @override
  String get automaticCategory => 'Categoría automática';

  @override
  String get hideApp => 'Ocultar';

  @override
  String get appInfo => 'Información de la app';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String appHidden(Object app) {
    return '$app oculta';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Automático';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get colors => 'Colores';

  @override
  String get colorSource => 'Origen del color';

  @override
  String get colorSystem => 'Sistema';

  @override
  String get colorSystemDesc => 'Sigue los colores de Android';

  @override
  String get colorPreset => 'Color elegido';

  @override
  String get paletteStyle => 'Estilo de la paleta';

  @override
  String get styleTonalSpot => 'Tonal';

  @override
  String get styleVibrant => 'Vivo';

  @override
  String get styleExpressive => 'Expresivo';

  @override
  String get styleNeutral => 'Neutro';

  @override
  String get styleMonochrome => 'Monocromo';

  @override
  String get contrast => 'Contraste';

  @override
  String get contrastStandard => 'Estándar';

  @override
  String get contrastMedium => 'Medio';

  @override
  String get contrastHigh => 'Alto';

  @override
  String get themedIcons => 'Iconos temáticos';

  @override
  String get themedIconsDesc =>
      'Iconos monocromos teñidos con la paleta (Android 13+)';

  @override
  String get preview => 'Vista previa';

  @override
  String get presetLaguna => 'Laguna';

  @override
  String get presetSalvia => 'Salvia';

  @override
  String get presetTerracotta => 'Terracota';

  @override
  String get presetAmbra => 'Ámbar';

  @override
  String get presetLampone => 'Frambuesa';

  @override
  String get presetLavanda => 'Lavanda';

  @override
  String get presetPetrolio => 'Petróleo';

  @override
  String get presetGrafite => 'Grafito';

  @override
  String get sectionApps => 'Apps';

  @override
  String get allAppsLayout => 'Vista de Todas las apps';

  @override
  String get showSystemApps => 'Mostrar apps del sistema';

  @override
  String get showSystemAppsDesc =>
      'Teléfono, Cámara, Ajustes y apps preinstaladas';

  @override
  String get hiddenApps => 'Apps ocultas';

  @override
  String get hiddenAppsEmpty => 'No hay apps ocultas';

  @override
  String get restore => 'Restaurar';

  @override
  String get fixedOrder => 'Orden fijo de Collections';

  @override
  String get fixedOrderDesc =>
      'No reordenar tarjetas e iconos según el contexto';

  @override
  String get hiddenCategories => 'Categorías ocultas';

  @override
  String get hiddenCategoriesEmpty => 'No hay categorías ocultas';

  @override
  String get sectionLanguage => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get sectionLauncher => 'Launcher';

  @override
  String get setDefault => 'Usar libreGLIDE como app de inicio';

  @override
  String get isDefault => 'libreGLIDE es la app de inicio predeterminada';

  @override
  String get androidSettings => 'Ajustes de Android';

  @override
  String get sectionData => 'Datos y privacidad';

  @override
  String launchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aperturas registradas',
      one: '1 apertura registrada',
      zero: 'Ninguna apertura registrada',
    );
    return '$_temp0';
  }

  @override
  String get privacyNote =>
      'Todos los datos se quedan en el teléfono y solo salen si los exportas tú. La base de datos está excluida de la copia de seguridad en la nube.';

  @override
  String get clearHistory => 'Borrar historial de aperturas';

  @override
  String get clearHistoryConfirm =>
      '¿Borrar el historial? Las predicciones empezarán desde cero.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Borrar';

  @override
  String get historyCleared => 'Historial borrado';

  @override
  String get diagnostics => 'Diagnóstico';

  @override
  String get diagnosticsDesc =>
      'Contexto actual y por qué se predicen las apps';

  @override
  String get currentContext => 'Contexto actual';

  @override
  String get predictions => 'Predicciones';

  @override
  String get noPredictions =>
      'Una app necesita al menos 3 aperturas para poder predecirse.';

  @override
  String get sectionAbout => 'Información';

  @override
  String get aboutDesc =>
      'Launcher contextual de código abierto que funciona solo en local.';

  @override
  String get tabSpace => 'Space';

  @override
  String get tabCollections => 'Collections';

  @override
  String get tabAllApps => 'A-Z';

  @override
  String get spacesTitle => 'Spaces';

  @override
  String get azHeader => 'Apps A-Z';

  @override
  String get actionAlarm => 'Alarma';

  @override
  String get actionDnd => 'No molestar';

  @override
  String get infoBanner =>
      'Aquí aparecerá información útil a lo largo del día.';

  @override
  String get nowAppsHeader => 'Para este momento';

  @override
  String get nextAlarm => 'Próxima alarma';

  @override
  String get noAlarm => 'No hay alarmas';

  @override
  String get addToDock => 'Añadir al dock';

  @override
  String get searchApps => 'Buscar';

  @override
  String get searchTopApps => 'Apps sobre la búsqueda';

  @override
  String get searchTopAppsDesc =>
      'Las más usadas en este contexto, encima de los resultados de búsqueda.';

  @override
  String hiddenSummary(int apps, int categories) {
    return '$apps apps, $categories categorías';
  }

  @override
  String get languageSystemShort => 'Sistema';

  @override
  String version(Object version) {
    return 'Versión $version';
  }

  @override
  String get agendaToday => 'Hoy';

  @override
  String get agendaTomorrow => 'Mañana';

  @override
  String get noEventsToday => 'No hay eventos hoy';

  @override
  String get noEventsTomorrow => 'No hay eventos mañana';

  @override
  String get allDay => 'Todo el día';

  @override
  String get agendaPermission =>
      'Muestra aquí tus próximos eventos del calendario.';

  @override
  String get allow => 'Permitir';

  @override
  String get newEvent => 'Nuevo evento';

  @override
  String get navigate => 'Cómo llegar';

  @override
  String get nowPlaying => 'Reproduciendo';

  @override
  String get mediaPermission =>
      'Controla tu música desde aquí. Se necesita acceso a las notificaciones: libreGLIDE lo usa solo para los controles multimedia y nunca lee ni guarda notificaciones.';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get sectionSpace => 'Space';

  @override
  String get cardAgenda => 'Agenda';

  @override
  String get cardAgendaDesc => 'Próximos eventos del calendario del teléfono';

  @override
  String get cardMedia => 'Reproduciendo';

  @override
  String get cardMediaDesc =>
      'Controles de la música que suena, también al conectar los auriculares';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get privacyPolicyDesc => 'Qué se queda en el teléfono y qué no';

  @override
  String get openSource => 'Bibliotecas de código abierto';

  @override
  String get openSourceDesc =>
      'Licencias de los componentes que usa libreGLIDE';

  @override
  String openSourceCount(int count) {
    return '$count componentes';
  }

  @override
  String licenseCount(int count) {
    return '$count licencias';
  }

  @override
  String get appLicense => 'Licencia de libreGLIDE';

  @override
  String get appLicenseUndefined => 'Por definir antes de la publicación';

  @override
  String get unsplashAttribution =>
      'Las fotos de los fondos son de autores de Unsplash, citados en Inicio y en el Space';

  @override
  String get showOnboarding => 'Ver de nuevo la introducción';

  @override
  String get obWelcomeTitle => 'Te damos la bienvenida a libreGLIDE';

  @override
  String get obWelcomeText =>
      'El launcher que cambia con tu momento: te muestra las apps y la información adecuadas cuando las necesitas.';

  @override
  String get obStart => 'Empezar';

  @override
  String get obNext => 'Siguiente';

  @override
  String get obBack => 'Atrás';

  @override
  String get obHowTitle => 'Cómo funciona';

  @override
  String get obHowSpace =>
      'El Space muestra tu agenda, tu música y las apps adecuadas para este momento.';

  @override
  String get obHowHome =>
      'Inicio deja sitio a tu fondo de pantalla, con un dock de tus apps favoritas.';

  @override
  String get obHowCollections =>
      'Collections agrupa tus apps automáticamente y pone primero las que usas ahora.';

  @override
  String get obHowSearch =>
      'Desliza hacia arriba para buscar una app y hacia abajo para tus contactos.';

  @override
  String get obHowDrawer =>
      'Toca las franjas de colores de arriba para elegir un Space.';

  @override
  String get obPrivacyTitle => 'Tu privacidad';

  @override
  String get obPrivacy1 => 'Sin cuenta, sin anuncios, sin telemetría.';

  @override
  String get obPrivacy2 =>
      'Tus hábitos se quedan en el teléfono: el desarrollador nunca los ve.';

  @override
  String get obPrivacy3 =>
      'Internet solo si eliges el fondo de Unsplash con tu propia clave.';

  @override
  String get obReadPolicy => 'Leer la política completa';

  @override
  String get obCollectionsTitle => 'Tus colecciones';

  @override
  String get obCollectionsText =>
      '¿Cuáles usas más? Se quedarán arriba las primeras semanas; después mandará tu uso real.';

  @override
  String get obCollectionsHint =>
      'Elige las que quieras, o ninguna. El orden en que las eliges cuenta.';

  @override
  String get obFinishTitle => 'Últimos retoques';

  @override
  String get obDockPrefill =>
      'Sugerir un dock con teléfono, mensajes, cámara y navegador';

  @override
  String get obFinish => 'Listo';

  @override
  String photoBy(Object name) {
    return 'Foto de $name · Unsplash';
  }

  @override
  String get sectionWallpaper => 'Fondo de pantalla';

  @override
  String get contextWallpaper => 'Fondo contextual';

  @override
  String get contextWallpaperDesc =>
      'En el Space, una foto de Unsplash que cambia con el momento: festivos, viajes, tiempo, hora del día, música. Solo dentro de libreGLIDE: el fondo de tu teléfono nunca se toca.';

  @override
  String get spaceHeaderBlur => 'Desenfocar la foto del Space';

  @override
  String get spaceHeaderBlurDesc =>
      'Ligeramente desenfocada detrás de la fecha y el nombre del Space, para leerlos mejor.';

  @override
  String get creditHome => 'Créditos en Inicio';

  @override
  String get creditSpace => 'Créditos en el Space';

  @override
  String get creditDesc =>
      'Fotógrafo y Unsplash sobre la foto, como piden las normas de Unsplash. Si los ocultas, siguen aquí abajo.';

  @override
  String get currentPhotoHome => 'Foto de Inicio';

  @override
  String get currentPhotoSpace => 'Foto del Space';

  @override
  String get dailyWallpaper => 'Fondo diario';

  @override
  String get dailyWallpaperDesc =>
      'Una nueva foto de Unsplash cada día en Inicio, elegida la primera vez que lo abres.';

  @override
  String get changeDailyPhoto => 'Cambiar la foto de hoy';

  @override
  String get wallpaperStyle => 'Estilo de las fotos';

  @override
  String get photoStyleNone => 'Ninguno';

  @override
  String get photoStyleAesthetic => 'Aesthetic';

  @override
  String get photoStyleNature => 'Naturaleza';

  @override
  String get photoStyleMinimal => 'Minimalista';

  @override
  String get photoStyleAbstract => 'Abstracto';

  @override
  String get photoStyleArchitecture => 'Arquitectura';

  @override
  String get photoStyleDark => 'Oscuro';

  @override
  String get unsplashKey => 'Clave de Unsplash';

  @override
  String get unsplashKeyNone => 'Sin configurar';

  @override
  String unsplashKeySet(Object hint) {
    return 'Configurada ($hint)';
  }

  @override
  String get unsplashKeyHelp =>
      'Crea una aplicación gratuita en unsplash.com/developers y pega aquí su Access Key. La clave se queda en el teléfono.';

  @override
  String get unsplashGetKey => 'Obtener una clave';

  @override
  String get save => 'Guardar';

  @override
  String get remove => 'Quitar';

  @override
  String get keyInvalid => 'Clave no válida';

  @override
  String get keyCheckFailed =>
      'No se pudo verificar la clave: revisa la conexión';

  @override
  String get changePhoto => 'Cambiar foto';

  @override
  String changePhotoDesc(Object moment) {
    return 'Otra foto para este momento: $moment';
  }

  @override
  String get wallpaperError =>
      'Foto no disponible: se muestra el fondo del teléfono';

  @override
  String get wallpaperNetworkNote =>
      'Usa Internet solo cuando cambia el momento, con tu clave. Sin clave, libreGLIDE nunca se conecta.';

  @override
  String get sectionGestures => 'Gestos';

  @override
  String get swipeDownAction => 'Deslizar hacia abajo';

  @override
  String get swipeUpAction => 'Deslizar hacia arriba';

  @override
  String get gestureSearch => 'Búsqueda';

  @override
  String get gestureContacts => 'Contactos';

  @override
  String get gestureNone => 'Nada';

  @override
  String get gesturesDesc =>
      'En Inicio y, al deslizar hacia abajo, también en la barra superior. En la búsqueda y los contactos, el deslizamiento contrario cierra y vuelve a Inicio.';

  @override
  String get collectionLabels => 'Nombres en Collections';

  @override
  String get collectionLabelsDesc =>
      'Mostrar nombres bajo los iconos también en las filas contraídas';

  @override
  String get contactsTitle => 'Contactos';

  @override
  String get contactsFavorites => 'Favoritos y más usados';

  @override
  String get contactsSearchHint => 'Buscar contactos';

  @override
  String get contactsPermission =>
      'Muestra aquí tus contactos favoritos y los más usados. Los contactos solo se leen en el teléfono.';

  @override
  String get contactsEmpty =>
      'Marca con una estrella tus contactos favoritos en la app Contactos: aparecerán aquí, junto con los que más abres.';

  @override
  String get noContactsFound => 'No se encontraron contactos';

  @override
  String get call => 'Llamar';

  @override
  String get message => 'Mensaje';

  @override
  String get openContact => 'Ficha del contacto';

  @override
  String get searchCollections => 'Explorar colecciones';

  @override
  String get cardEvening => 'Buenas noches';

  @override
  String get cardEveningDesc =>
      'Por la noche: la alarma de mañana, No molestar y un recordatorio para cargar';

  @override
  String get dndOn => 'No molestar activado';

  @override
  String chargeReminder(int level) {
    return 'Batería al $level%: cárgalo durante la noche';
  }

  @override
  String get cardNextPlace => 'Próximo destino';

  @override
  String get cardNextPlaceDesc =>
      'Indicaciones para tu próximo evento con lugar, en las 3 horas anteriores';

  @override
  String get cardTravel => 'De viaje';

  @override
  String get cardTravelDesc =>
      'La hora de casa y apps de viaje cuando estás en otra zona horaria o en roaming';

  @override
  String homeTime(Object time) {
    return 'En casa son las $time';
  }

  @override
  String get travelHere => 'Ahora vivo aquí';

  @override
  String get autoLaunch => 'Abrir la única app que coincida';

  @override
  String get autoLaunchDesc =>
      'Cuando solo una app coincide con lo que escribes (al menos 2 letras), se abre automáticamente.';

  @override
  String get sectionSearchGestures => 'Búsqueda y gestos';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get cardWidgets => 'Widgets';

  @override
  String get cardWidgetsDesc =>
      'Widgets de Android a todo lo ancho en el Space';

  @override
  String get addWidget => 'Añadir widget';

  @override
  String get noWidgets => 'No hay widgets en el Space: añade uno.';

  @override
  String get widgetHeight => 'Altura';

  @override
  String get widgetShorter => 'Más bajo';

  @override
  String get widgetTaller => 'Más alto';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String widgetMinSize(int w, int h) {
    return 'Mínimo $w×$h dp';
  }

  @override
  String widgetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count widgets',
      one: '1 widget',
      zero: 'Ningún widget',
    );
    return '$_temp0';
  }

  @override
  String get cardWeather => 'Tiempo';

  @override
  String get cardWeatherDesc =>
      'Previsión de Open-Meteo con tu ubicación aproximada, redondeada a unos 10 km. Usa Internet.';

  @override
  String get weatherPermission =>
      'El tiempo necesita tu ubicación aproximada: se redondea a unos 10 km antes de pedir la previsión.';

  @override
  String get weatherHere => 'Aquí';

  @override
  String get weatherSource =>
      'Datos meteorológicos: Open-Meteo.com (CC BY 4.0)';

  @override
  String get weatherClear => 'Despejado';

  @override
  String get weatherPartly => 'Parcialmente nublado';

  @override
  String get weatherCloudy => 'Nublado';

  @override
  String get weatherFog => 'Niebla';

  @override
  String get weatherDrizzle => 'Llovizna';

  @override
  String get weatherRain => 'Lluvia';

  @override
  String get weatherSnow => 'Nieve';

  @override
  String get weatherShowers => 'Chubascos';

  @override
  String get weatherStorm => 'Tormenta';

  @override
  String get cardCar => 'En el coche';

  @override
  String get cardCarDesc =>
      'Mapas, música y tu próximo destino mientras conduces (Android Auto o radio del coche Bluetooth)';

  @override
  String get carBluetooth => 'Reconocer la radio Bluetooth del coche';

  @override
  String get carBluetoothDesc =>
      'Opcional: necesita el permiso Dispositivos cercanos. Sin él, solo se reconoce Android Auto.';

  @override
  String get screenTime => 'Tiempo de pantalla';

  @override
  String get screenTimeDesc =>
      'Cuánto has usado el teléfono hoy, como en Olauncher. Necesita acceso al uso; los datos se quedan en el teléfono.';

  @override
  String get screenTimeOff => 'Desactivado';

  @override
  String get screenTimeHome => 'Inicio';

  @override
  String get screenTimeSpace => 'Space';

  @override
  String get screenTimeToday => 'Hoy';

  @override
  String get screenTimePermission =>
      'Para mostrar el tiempo de pantalla se necesita acceso al uso. Los datos se quedan en el teléfono.';

  @override
  String durationHM(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationM(int m) {
    return '$m min';
  }

  @override
  String get spaceHome => 'Casa';

  @override
  String get spaceWork => 'Trabajo';

  @override
  String get spaceSchool => 'Escuela';

  @override
  String get spaceWorkOrSchool => 'Trabajo/Escuela';

  @override
  String get spaceMoving => 'En movimiento';

  @override
  String get spaceListening => 'Escuchando';

  @override
  String get spaceTravel => 'De viaje';

  @override
  String get spaceNightOut => 'Noche fuera';

  @override
  String get spaceExercise => 'Actividad física';

  @override
  String get exerciseSpaceDesc =>
      'Un Space para correr y caminar rápido, detectados con el podómetro del teléfono cuando abres el launcher. Sin servicio en segundo plano.';

  @override
  String get spacesPlaces => 'Por lugar';

  @override
  String get spacesContext => 'Según el contexto';

  @override
  String get spacesTime => 'Según la hora del día';

  @override
  String get actionEmail => 'Correo';

  @override
  String get actionToHome => 'Ir a casa';

  @override
  String get actionToWork => 'Ir al trabajo';

  @override
  String get actionMaps => 'Mapas';

  @override
  String get sectionPlaces => 'Lugares';

  @override
  String get placesEnabled => 'Reconocer casa y trabajo';

  @override
  String get placesEnabledDesc =>
      'Los Spaces Casa y Trabajo/Escuela se activan solos. Usa la ubicación precisa solo mientras usas el launcher, y el Wi-Fi como huella cifrada; todo se queda en el teléfono.';

  @override
  String get placesPermission =>
      'Para reconocer casa y trabajo se necesita la ubicación precisa, solo mientras usas el launcher. Las coordenadas y las redes Wi-Fi se quedan en el teléfono y nunca se envían.';

  @override
  String get placeHome => 'Casa';

  @override
  String get placeWork => 'Trabajo/Escuela';

  @override
  String placeRecognized(int percent) {
    return 'Reconocido ($percent%)';
  }

  @override
  String get placeByUser => 'Configurado por ti';

  @override
  String get placeLearningHome => 'Aprendiendo: hacen falta algunas noches';

  @override
  String get placeLearningWork =>
      'Aprendiendo: hacen falta algunos días laborables';

  @override
  String get workLabel => 'Nombre del Space de trabajo';

  @override
  String get workLabelWork => 'Trabajo';

  @override
  String get workLabelSchool => 'Escuela';

  @override
  String get hereIsHome => 'Esta es mi casa';

  @override
  String get hereIsWork => 'Este es mi trabajo/escuela';

  @override
  String get notHome => 'Esta no es mi casa';

  @override
  String get notWork => 'Este no es mi trabajo/escuela';

  @override
  String get hereUnknown =>
      'Aún no se conoce el lugar actual: vuelve tras unos minutos en el launcher.';

  @override
  String get resetPlaces => 'Restablecer lugares';

  @override
  String get resetPlacesConfirm =>
      '¿Olvidar todos los lugares y las muestras de ubicación? Casa y trabajo se reconocerán de nuevo.';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugares',
      one: '1 lugar',
      zero: 'Ningún lugar',
    );
    return '$_temp0';
  }

  @override
  String get editHome => 'Editar widgets';

  @override
  String homeWidgetsFull(int max) {
    return 'Hasta $max widgets en Inicio';
  }

  @override
  String get done => 'Listo';

  @override
  String widgetRows(int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows filas',
      one: '1 fila',
    );
    return '$_temp0';
  }

  @override
  String get cardParking => 'Dónde aparqué';

  @override
  String get cardParkingDesc =>
      'Al desconectarte de la radio Bluetooth del coche, guarda dónde lo dejaste. Usa la ubicación en segundo plano solo en ese momento; se queda en el teléfono.';

  @override
  String parkedAt(Object time, Object ago) {
    return 'Aparcado a las $time · $ago';
  }

  @override
  String parkedImprecise(int meters) {
    return 'Posición aproximada ($meters m)';
  }

  @override
  String get forget => 'Olvidar';

  @override
  String agoMinutes(int m) {
    return 'hace $m min';
  }

  @override
  String agoHours(int h) {
    return 'hace $h h';
  }

  @override
  String get parkingNeedsBluetooth =>
      'Para reconocer el coche se necesita el permiso Dispositivos cercanos.';

  @override
  String get parkingNeedsPrecise =>
      'Para guardar el sitio se necesita la ubicación precisa.';

  @override
  String get parkingNeedsBackground =>
      'Para guardar el sitio al bajar del coche (con el teléfono en el bolsillo) se necesita la ubicación \"Permitir todo el tiempo\". Solo se usa al desconectarte de la radio del coche.';

  @override
  String get parkingWaiting =>
      'El sitio se guardará la próxima vez que te desconectes de la radio del coche.';

  @override
  String get spaceAutomatic => 'Automático';

  @override
  String get spaceNow => 'ahora';

  @override
  String get workLabelAutomatic => 'Automático';

  @override
  String get workKindLearning =>
      'Tras unos días distingue por tus horarios si es trabajo (mañana y tarde) o escuela (solo mañanas).';

  @override
  String workKindDetected(String kind) {
    return 'Detectado por tus horarios: $kind';
  }

  @override
  String get groupLook => 'Aspecto y contenido';

  @override
  String get groupBehavior => 'Comportamiento';

  @override
  String get groupSystem => 'Sistema';

  @override
  String get stateOn => 'Activado';

  @override
  String get stateOff => 'Desactivado';

  @override
  String cardsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas activas',
      one: '1 tarjeta activa',
      zero: 'Ninguna tarjeta activa',
    );
    return '$_temp0';
  }

  @override
  String get parkingBackgroundBlocked =>
      'Android ya no muestra la solicitud. Abre los ajustes de la app, luego Permisos › Ubicación y elige \"Permitir todo el tiempo\". La ubicación solo se lee al desconectarte de la radio del coche.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get turnOff => 'Desactivar';

  @override
  String get obHowDetox =>
      'Digital detox (en los ajustes): bloquea las apps que te distraen, todo el día o en una franja horaria, con un PIN.';

  @override
  String get notNow => 'Ahora no';

  @override
  String get ok => 'OK';

  @override
  String get detoxTitle => 'Digital detox';

  @override
  String get detoxDesc =>
      'Bloquea las apps que elijas, todo el día o en una franja horaria. Al abrirlas aparece una pantalla negra.';

  @override
  String get detoxServiceTitle => 'Activa el servicio de bloqueo';

  @override
  String get detoxServiceExplain =>
      'Para saber cuándo abres una app bloqueada, libreGLIDE usa un servicio de accesibilidad. Solo recibe el nombre de la app que pasa a primer plano: no lee la pantalla, no registra nada y no gasta batería si no cambias de app.\n\nEn los ajustes que se abren, activa \"libreGLIDE · Digital detox\". Si Android lo muestra desactivado (\"ajuste restringido\"), abre la información de la app libreGLIDE, menú ⋮, \"Permitir ajustes restringidos\".';

  @override
  String get detoxServiceOpen => 'Abrir ajustes';

  @override
  String get detoxServiceOff => 'El servicio de bloqueo está desactivado';

  @override
  String get detoxServiceOffDesc =>
      'Las apps solo se bloquean si se abren desde libreGLIDE. Toca para activarlo.';

  @override
  String get detoxServiceOn => 'El servicio de bloqueo está activado';

  @override
  String get detoxActiveNow => 'El bloqueo está activo ahora.';

  @override
  String detoxStartsAt(String time) {
    return 'El bloqueo empieza a las $time.';
  }

  @override
  String get detoxPin => 'PIN';

  @override
  String get detoxSetPin => 'Configurar PIN';

  @override
  String get detoxChangePin => 'Cambiar PIN';

  @override
  String get detoxPinDesc =>
      'De 8 a 16 caracteres. Se necesita para desbloquear apps y para cambiar estos ajustes mientras el detox está activo.';

  @override
  String get detoxPinLabel => 'PIN';

  @override
  String get detoxOldPin => 'PIN actual';

  @override
  String get detoxNewPin => 'PIN nuevo';

  @override
  String get detoxConfirmPin => 'Confirmar PIN';

  @override
  String get detoxPinLength => 'De 8 a 16 caracteres.';

  @override
  String get detoxPinMismatch => 'Los dos PIN no coinciden.';

  @override
  String get detoxPinWarning =>
      'No lo pierdas: no se puede recuperar. Sin el PIN, la única forma de salir del detox es reiniciar el teléfono en modo seguro.';

  @override
  String get detoxWrongPin => 'PIN incorrecto.';

  @override
  String detoxWait(int seconds) {
    return 'Demasiados intentos. Vuelve a intentarlo en $seconds s.';
  }

  @override
  String get detoxSchedule => 'Horario';

  @override
  String get detoxWhen => 'Cuándo';

  @override
  String get detoxAllDay => 'Todo el día';

  @override
  String get detoxTimeRange => 'Franja horaria';

  @override
  String get detoxFrom => 'Desde';

  @override
  String get detoxTo => 'Hasta';

  @override
  String get detoxUnlock => 'Desbloqueo';

  @override
  String get detoxUnlockTitle => 'Apps bloqueadas';

  @override
  String get detoxUnlockPin => 'Con PIN';

  @override
  String get detoxUnlockNever => 'Nunca';

  @override
  String get detoxUnlockPinDesc =>
      'Con el PIN, la app sigue abierta hasta que salgas de ella.';

  @override
  String get detoxUnlockNeverDesc =>
      'Sin desbloqueo: solo puedes volver a Inicio.';

  @override
  String get detoxApps => 'Apps';

  @override
  String get detoxLockedApps => 'Apps bloqueadas';

  @override
  String detoxAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
      zero: 'Ninguna app',
    );
    return '$_temp0';
  }

  @override
  String get detoxHide => 'Ocultar apps bloqueadas';

  @override
  String get detoxHideDesc =>
      'Durante el detox desaparecen de Collections, A-Z, la búsqueda y el dock. Se guardan aparte de las apps ocultas: cuando termina el detox vuelven a su sitio.';

  @override
  String get detoxEmergency =>
      'Si bloqueas Ajustes, necesitarás el PIN aquí en libreGLIDE para desactivar el detox. Si lo pierdes, reinicia en modo seguro: Android desactiva los servicios de accesibilidad.';

  @override
  String get detoxSystemGroup => 'Sistema';

  @override
  String get detoxSystemGroupDesc =>
      'Instalar y desinstalar, Ajustes, Play Store';

  @override
  String detoxGroupCount(int locked, int total) {
    return '$locked de $total bloqueadas';
  }

  @override
  String get frostedGlass => 'Cristal esmerilado';

  @override
  String get frostedGlassDesc =>
      'Space, Collections y A-Z se vuelven translúcidos sobre el fondo desenfocado. El desenfoque lo hace Android; con el ahorro de batería las páginas vuelven a ser opacas.';

  @override
  String get dockStyle => 'Dock';

  @override
  String get homeTabLabel => 'Pestaña Inicio';

  @override
  String get homeTabDate => 'Fecha';

  @override
  String get homeTabWeather => 'Tiempo';

  @override
  String get homeTabWeatherOff =>
      'Para ver el tiempo, activa la tarjeta Tiempo en los ajustes del Space.';

  @override
  String get dockTray => 'Bandeja';

  @override
  String get dockTransparent => 'Transparente';

  @override
  String get homeCorners => 'Esquinas redondeadas en Inicio';

  @override
  String get homeCornersDesc =>
      'La barra y el dock enmarcan el fondo con esquinas ligeramente redondeadas.';

  @override
  String get lockPortrait => 'Bloquear en vertical';

  @override
  String get lockPortraitDesc =>
      'El launcher se queda en vertical aunque gires el teléfono. Desactívalo para seguir la rotación automática.';

  @override
  String get learnFromUsage => 'Aprender también de apps abiertas fuera';

  @override
  String get learnFromUsageDesc =>
      'Usa el historial de uso de Android (notificaciones, recientes, enlaces) para sugerir las apps adecuadas desde el principio. Se queda en el teléfono; al desactivarlo se borra.';

  @override
  String get usageAccessNeeded => 'Permitir acceso a datos de uso';

  @override
  String get usageAccessNeededDesc =>
      'Es necesario para leer el historial de uso de Android.';

  @override
  String launchSourcesNote(int usage) {
    return '$usage del historial de Android';
  }

  @override
  String get weatherTomorrow => 'Mañana';

  @override
  String rainChance(int percent) {
    return 'Probabilidad de lluvia $percent%';
  }

  @override
  String get actionAlarmTomorrow => 'Alarma de mañana';

  @override
  String get actionTimer => 'Temporizador';

  @override
  String get actionFood => 'Dónde comer';

  @override
  String get foodQuery => 'restaurantes';

  @override
  String get cardShowHere => 'Mostrar siempre en este Space';

  @override
  String get cardHideHere => 'Ocultar en este Space';

  @override
  String get cardAuto => 'Automático (como antes)';

  @override
  String get cardCategory => 'Apps del momento';

  @override
  String get diagnosticsCards => 'Tarjetas del Space';

  @override
  String get spaceCards => 'Tarjetas por Space';

  @override
  String get spaceCardsEntryDesc => 'Elige qué tarjetas muestra cada Space';

  @override
  String get spaceCardsDesc =>
      'Automático sigue el momento y tu uso. Siempre y Nunca valen solo para ese Space y mandan sobre todo.';

  @override
  String spaceCardsCustom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elecciones personales',
      one: '1 elección personal',
    );
    return '$_temp0';
  }

  @override
  String get cardAutoShort => 'Automático';

  @override
  String get cardAlways => 'Siempre';

  @override
  String get cardNever => 'Nunca';

  @override
  String get cardDefaultShown => 'Visible de forma predeterminada';

  @override
  String get cardDefaultHidden => 'Oculta de forma predeterminada';

  @override
  String get manageSpaceCards => 'Gestionar las tarjetas de este Space…';

  @override
  String unsplashKeyVerified(String suffix) {
    return 'Clave verificada · $suffix';
  }
}
