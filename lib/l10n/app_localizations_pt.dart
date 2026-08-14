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
  String workoutPrevious(int sets, int reps, String weight) {
    return 'anterior $sets×$reps · ${weight}kg';
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
  String summaryBestSet(String weight, int reps) {
    return '${weight}kg × $reps';
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
  String get bodyNotBuilt => 'Medições ainda não existem.';

  @override
  String get bodyNotBuiltBody =>
      'Peso e medidas corporais chegam numa versão futura.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileNotBuilt => 'Ainda não há conta.';

  @override
  String get profileNotBuiltBody =>
      'Tudo que você registra fica neste aparelho. Conta e sincronização vêm depois.';

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
  String shareSubject(String routine, String volume) {
    return '$routine · $volume kg';
  }

  @override
  String get shareFailed => 'Não foi possível gerar a imagem.';
}
