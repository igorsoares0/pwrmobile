// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'PWR';

  @override
  String get homeGreeting => 'Bom treino.';

  @override
  String homeWeekLabel(String weekday, int week) {
    return '$weekday · semana $week';
  }

  @override
  String get homeStatWorkouts => 'treinos\nna semana';

  @override
  String get homeStatVolume => 'volume\ntotal';

  @override
  String get homeStatSets => 'séries\nna semana';

  @override
  String get homeRoutinesTitle => 'Suas rotinas';

  @override
  String homeRoutinesCounter(int used, int limit) {
    return '$used/$limit no free';
  }

  @override
  String homeRoutinesUnlimited(int used) {
    return '$used rotinas';
  }

  @override
  String homeRoutineSubtitle(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercícios',
      one: '1 exercício',
      zero: 'sem exercícios',
    );
    return '$_temp0 · ~$minutes min';
  }

  @override
  String get homeNewRoutine => 'Nova rotina';

  @override
  String get homeNewRoutineLocked => 'Limite do plano Free atingido';

  @override
  String get homeNewRoutineHint => 'Monte a primeira';

  @override
  String get homeEmptyTitle => 'Nenhuma rotina ainda.';

  @override
  String get homeEmptyBody =>
      'Uma rotina é a lista de exercícios que você repete. Monte uma e todo treino depois deste leva três toques.';

  @override
  String get homeEmptyAction => 'Criar rotina';

  @override
  String get homeLibrary => 'Biblioteca de exercícios';

  @override
  String homeLibraryCount(int count) {
    return '$count exercícios';
  }

  @override
  String get homeResumeWorkout => 'Treino em andamento';

  @override
  String get homeResumeAction => 'Retomar';

  @override
  String get unitTonnesShort => 't';

  @override
  String get unitKilogramsShort => 'kg';

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get librarySearchHint => 'Buscar exercício…';

  @override
  String get libraryFilterAll => 'Todos';

  @override
  String librarySection(String region, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercícios',
      one: '1 exercício',
    );
    return '$region · $_temp0';
  }

  @override
  String get libraryCreateCustom => 'Criar exercício próprio';

  @override
  String get libraryCreateCustomHint => 'O que faltar na biblioteca';

  @override
  String libraryEmptySearch(String query) {
    return 'Nada encontrado para “$query”.';
  }

  @override
  String get libraryEmptySearchBody =>
      'Confira a grafia, ou cadastre como exercício próprio.';

  @override
  String get libraryCustomBadge => 'Seu';

  @override
  String get createExerciseTitle => 'Novo exercício';

  @override
  String get createExerciseNameLabel => 'Nome';

  @override
  String get createExerciseNameHint => 'ex.: Hack invertido';

  @override
  String get createExerciseMuscleLabel => 'Músculo principal';

  @override
  String get createExerciseEquipmentLabel => 'Equipamento';

  @override
  String get createExerciseSave => 'Salvar exercício';

  @override
  String get createExerciseNameRequired => 'Dê um nome primeiro.';

  @override
  String get regionChest => 'Peito';

  @override
  String get regionBack => 'Costas';

  @override
  String get regionShoulders => 'Ombro';

  @override
  String get regionArms => 'Braço';

  @override
  String get regionLegs => 'Pernas';

  @override
  String get regionCore => 'Core';

  @override
  String get regionOther => 'Outros';

  @override
  String get muscleChest => 'Peito';

  @override
  String get muscleBack => 'Costas';

  @override
  String get muscleShoulders => 'Ombro';

  @override
  String get muscleBiceps => 'Bíceps';

  @override
  String get muscleTriceps => 'Tríceps';

  @override
  String get muscleForearms => 'Antebraço';

  @override
  String get muscleQuads => 'Quadríceps';

  @override
  String get muscleHamstrings => 'Posterior';

  @override
  String get muscleGlutes => 'Glúteo';

  @override
  String get muscleCalves => 'Panturrilha';

  @override
  String get muscleCore => 'Core';

  @override
  String get muscleCardio => 'Cardio';

  @override
  String get muscleOther => 'Outros';

  @override
  String get equipmentBarbell => 'Barra';

  @override
  String get equipmentDumbbell => 'Halteres';

  @override
  String get equipmentMachine => 'Máquina';

  @override
  String get equipmentCable => 'Polia';

  @override
  String get equipmentBodyweight => 'Peso corporal';

  @override
  String get equipmentKettlebell => 'Kettlebell';

  @override
  String get equipmentBand => 'Elástico';

  @override
  String get equipmentOther => 'Outros';

  @override
  String get routineNew => 'Nova rotina';

  @override
  String get routineEdit => 'Editar rotina';

  @override
  String get routineDefaultName => 'Nova rotina';

  @override
  String get routineNameLabel => 'Nome da ficha';

  @override
  String get routineNameHint => 'ex.: Push A';

  @override
  String get routineFocusLabel => 'Foco';

  @override
  String get routineFocusHint => 'ex.: Peito & tríceps';

  @override
  String routineExercisesHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'exercícios · $count',
      one: 'exercícios · 1',
      zero: 'exercícios',
    );
    return '$_temp0';
  }

  @override
  String get routineReorderHint => 'arraste para reordenar';

  @override
  String get routineAddExercise => 'Adicionar exercício';

  @override
  String get routineNoExercises => 'Nenhum exercício ainda.';

  @override
  String get routineNoExercisesBody =>
      'Adicione os movimentos que você faz, na ordem em que faz.';

  @override
  String routineSlotSummary(int sets, int rest) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets séries',
      one: '1 série',
    );
    return '$_temp0 · desc. ${rest}s';
  }

  @override
  String routineSlotSummaryWithReps(int sets, int reps, int rest) {
    return '$sets×$reps · desc. ${rest}s';
  }

  @override
  String get routineSupersetMarker => 'supersérie com o próximo';

  @override
  String get routineSupersetToggle => 'Emendar com o próximo exercício';

  @override
  String get routineDone => 'Concluir';

  @override
  String get routineDelete => 'Excluir rotina';

  @override
  String get routineDeleteConfirm =>
      'Excluir esta rotina? Os treinos já registrados a partir dela são mantidos.';

  @override
  String routineLimitTitle(int limit) {
    return 'O plano Free permite $limit rotinas.';
  }

  @override
  String get routineLimitBody =>
      'Exclua uma para abrir espaço, ou assine o PRO para rotinas ilimitadas.';

  @override
  String get slotSets => 'Séries';

  @override
  String get slotReps => 'Repetições alvo';

  @override
  String get slotRepsAny => 'Livre';

  @override
  String get slotRest => 'Descanso';

  @override
  String slotRestSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get slotRemove => 'Remover da rotina';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String workoutInProgress(int current, int total) {
    return 'em andamento · ex. $current de $total';
  }

  @override
  String get workoutTotal => 'total';

  @override
  String get workoutColSet => 'série';

  @override
  String get workoutColWeight => 'kg';

  @override
  String get workoutColReps => 'reps';

  @override
  String get workoutColDone => 'ok';

  @override
  String get workoutSetWarmup => 'W';

  @override
  String get workoutSetFailure => 'F';

  @override
  String get workoutSetDrop => 'D';

  @override
  String get workoutSuperset => 'supersérie';

  @override
  String workoutPrevious(int sets, int reps, String weight, String unit) {
    return 'anterior $sets×$reps · $weight$unit';
  }

  @override
  String get workoutNoPrevious => 'primeira vez';

  @override
  String workoutNext(String name) {
    return 'a seguir · $name';
  }

  @override
  String get workoutLastExercise => 'último exercício';

  @override
  String get workoutAddSet => 'Adicionar série';

  @override
  String get workoutRest => 'descanso';

  @override
  String get workoutRestPaused => 'pausado';

  @override
  String get workoutRestDone => 'pronto';

  @override
  String get workoutRestStart => 'Iniciar';

  @override
  String get workoutRestPause => 'Pausar';

  @override
  String get workoutRestResume => 'Retomar';

  @override
  String get workoutRestSkip => 'Pular';

  @override
  String get workoutRestAdd => '+30s';

  @override
  String get workoutFinish => 'Finalizar treino';

  @override
  String workoutFinishConfirm(int done, int planned) {
    return 'Finalizar este treino? $done de $planned séries marcadas.';
  }

  @override
  String get workoutFinishAction => 'Finalizar';

  @override
  String get workoutDiscard => 'Descartar treino';

  @override
  String get workoutEmpty => 'Este treino não tem exercícios.';

  @override
  String get workoutEmptyBody => 'Adicione um da biblioteca para começar.';

  @override
  String get workoutNoSession => 'Nenhum treino em andamento.';

  @override
  String summaryComplete(int minutes) {
    return 'treino concluído · $minutes min';
  }

  @override
  String summaryTitle(String name) {
    return '$name registrado.';
  }

  @override
  String get summaryTitleNoRoutine => 'Treino registrado.';

  @override
  String get summaryVolumeCaption => 'volume total';

  @override
  String summaryVsPrevious(String delta) {
    return '$delta vs. da última vez';
  }

  @override
  String get summaryFirstOnRoutine => 'primeira vez nesta rotina';

  @override
  String get summaryStatSets => 'séries';

  @override
  String get summaryStatExercises => 'exercícios';

  @override
  String get summaryStatDuration => 'minutos';

  @override
  String get summaryBestToday => 'seus melhores de hoje';

  @override
  String summaryBestSet(String weight, String unit, int reps) {
    return '$weight$unit × $reps';
  }

  @override
  String summaryBodyweightSet(int reps) {
    return '$reps reps';
  }

  @override
  String get summaryNothingLogged => 'Nada foi marcado.';

  @override
  String get summaryNothingLoggedBody =>
      'A sessão foi salva, mas nenhuma série foi registrada nela.';

  @override
  String get summaryClose => 'Concluir';

  @override
  String get summaryMissing => 'Esse treino não existe mais.';

  @override
  String get historyTitle => 'Histórico';

  @override
  String historyMonth(String month, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treinos',
      one: '1 treino',
    );
    return '$month · $_temp0';
  }

  @override
  String historyRowSubtitle(String day, int sets, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets séries',
      one: '1 série',
    );
    return '$day · $_temp0 · $minutes min';
  }

  @override
  String get historyFreestyle => 'Treino livre';

  @override
  String get historyEmpty => 'Nenhum treino ainda.';

  @override
  String get historyEmptyBody =>
      'Finalize uma sessão e ela aparece aqui, com tudo que você levantou.';

  @override
  String get navWorkout => 'treino';

  @override
  String get navHistory => 'histórico';

  @override
  String get navBody => 'corpo';

  @override
  String get navProfile => 'perfil';

  @override
  String get navStartWorkout => 'Iniciar treino';

  @override
  String get workoutAddExercise => 'Adicionar exercício';

  @override
  String get bodyTitle => 'Corpo';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get bodyCurrentWeight => 'peso atual';

  @override
  String get bodyNoBaseline => 'primeiro registro';

  @override
  String bodyDeltaWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas',
      one: '1 semana',
      zero: 'menos de uma semana',
    );
    return 'em $_temp0';
  }

  @override
  String get bodyLogWeight => 'Registrar peso';

  @override
  String get bodyLogTitle => 'Pesagem';

  @override
  String get bodyLogDate => 'Data';

  @override
  String get bodyLogToday => 'Hoje';

  @override
  String get bodyLogSave => 'Salvar';

  @override
  String get bodyLogDelete => 'Excluir este registro';

  @override
  String get bodyHistory => 'Histórico';

  @override
  String get bodyEmptyHeadline => 'Nenhuma pesagem ainda.';

  @override
  String get bodyEmptyBody =>
      'Um número por semana já basta. É a linha embaixo de todos os outros números do app — volume significa uma coisa a 74 kg e outra a 82.';

  @override
  String get bodyMeasurements => 'Medidas';

  @override
  String get bodyMeasurementsLocked =>
      'Peito, cintura, braço e coxa — e fotos de evolução — fazem parte do PRO.';

  @override
  String get bodyChest => 'Peito';

  @override
  String get bodyWaist => 'Cintura';

  @override
  String get bodyArm => 'Braço';

  @override
  String get bodyThigh => 'Coxa';

  @override
  String get bodyLocked => 'PRO';

  @override
  String get profileAccountTitle => 'Este aparelho';

  @override
  String get profileAccountSubtitle => 'plano free';

  @override
  String get profileAccountNote =>
      'Tudo que você registra fica aqui. Conta e sincronização na nuvem chegam numa versão futura.';

  @override
  String get profileSectionTraining => 'Treino';

  @override
  String get profileWeightUnit => 'Unidade de peso';

  @override
  String get profileWeightUnitSheet => 'Mostrar cargas em';

  @override
  String get profileDefaultRest => 'Descanso padrão';

  @override
  String get profileDefaultRestSheet => 'Descanso de um exercício novo';

  @override
  String get profileDefaultRestNote =>
      'Vale para os exercícios que você adicionar daqui em diante. Cada um ainda pode ser mudado individualmente.';

  @override
  String get profileTimerSound => 'Alerta sonoro do descanso';

  @override
  String get profileSectionData => 'Dados';

  @override
  String get profileExport => 'Exportar treinos (CSV)';

  @override
  String get profileExportSubtitle => 'todas as séries concluídas';

  @override
  String get profileExportEmpty =>
      'Ainda não há treino finalizado para exportar.';

  @override
  String get profileExportFailed => 'Não foi possível gerar o arquivo.';

  @override
  String profileExportSubject(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries',
      one: '1 série',
    );
    return 'PWR · $_temp0';
  }

  @override
  String get onboardingHeadline => 'Registre o treino em';

  @override
  String get onboardingHeadlineAccent => 'três toques.';

  @override
  String get onboardingBody =>
      'Carga, repetições e descanso. Sem rede social, sem distração — só o que você levantou.';

  @override
  String get onboardingStep1 => 'Escolha a rotina';

  @override
  String get onboardingStep1Body => 'Até 3 fichas no plano Free.';

  @override
  String get onboardingStep2 => 'Marque cada série';

  @override
  String get onboardingStep2Body => 'O app já preenche a carga anterior.';

  @override
  String get onboardingStep3 => 'Acompanhe a evolução';

  @override
  String get onboardingStep3Body => 'Volume e histórico de cada sessão.';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingOffline =>
      'Funciona sem sinal. Tudo fica neste aparelho.';

  @override
  String get shareAction => 'Compartilhar';

  @override
  String get sharePreviewTitle => 'Compartilhar este treino';

  @override
  String get shareConfirm => 'Compartilhar imagem';

  @override
  String get shareCardSets => 'séries';

  @override
  String get shareCardMinutes => 'min';

  @override
  String get shareCardBest => 'melhor série';

  @override
  String get shareCardFreestyle => 'Treino';

  @override
  String shareSubject(String routine, String volume, String unit) {
    return '$routine · $volume $unit';
  }

  @override
  String get shareFailed => 'Não foi possível gerar a imagem.';
}
