/obj/item/toy/plush
	name = "plush"
	desc = "This is the special coder plush, do not steal."
	icon = 'icons/obj/plushes.dmi'
	lefthand_file = 'icons/mob/inhands/plushes_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/plushes_righthand.dmi'
	icon_state = "debug"
	attack_verb_continuous = list("thumps", "whomps", "bumps")
	attack_verb_simple = list("thump", "whomp", "bump")
	w_class = WEIGHT_CLASS_SMALL
	item_flags = ISWEAPON
	resistance_flags = FLAMMABLE
	var/list/squeak_override //Weighted list; If you want your plush to have different squeak sounds use this
	var/stuffed = TRUE //If the plushie has stuffing in it
	var/obj/item/grenade/grenade //You can remove the stuffing from a plushie and add a grenade to it for *nefarious uses*
	gender = NEUTER
	var/obj/item/toy/plush/lover
	var/obj/item/toy/plush/partner
	var/obj/item/toy/plush/plush_child
	var/obj/item/toy/plush/paternal_parent	//who initiated creation
	var/obj/item/toy/plush/maternal_parent	//who owns, see love()
	var/static/list/breeding_blacklist = typecacheof(/obj/item/toy/plush/carpplushie/dehy_carp) // you cannot have sexual relations with this plush
	var/list/scorned	= list()	//who the plush hates
	var/list/scorned_by	= list()	//who hates the plush, to remove external references on Destroy()
	var/heartbroken = FALSE
	var/vowbroken = FALSE
	var/young = FALSE
	///Prevents players from cutting stuffing out of a plushie if true
	var/divine = FALSE
	var/mood_message
	var/list/love_message
	var/list/partner_message
	var/list/heartbroken_message
	var/list/vowbroken_message
	var/list/parent_message
	var/normal_desc

/obj/item/toy/plush/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/squeak, squeak_override)
	AddElement(/datum/element/bed_tuckable, 6, -5, 90)

	//have we decided if Pinocchio goes in the blue or pink aisle yet?
	if(gender == NEUTER)
		if(prob(50))
			gender = FEMALE
		else
			gender = MALE

	love_message		= list("\n[src] is so happy, \he could rip a seam!")
	partner_message		= list("\n[src] has a ring on \his finger! It says bound to my dear [partner].")
	heartbroken_message	= list("\n[src] looks so sad.")
	vowbroken_message	= list("\n[src] lost \his ring...")
	parent_message		= list("\n[src] can't remember what sleep is.")

	normal_desc = desc

/obj/item/toy/plush/Destroy()
	QDEL_NULL(grenade)

	//inform next of kin and... acquaintances
	if(partner)
		partner.bad_news(src)
		partner = null
		lover = null
	else if(lover)
		lover.bad_news(src)
		lover = null

	if(paternal_parent)
		paternal_parent.bad_news(src)
		paternal_parent = null

	if(maternal_parent)
		maternal_parent.bad_news(src)
		maternal_parent = null

	if(plush_child)
		plush_child.bad_news(src)
		plush_child = null

	var/i
	var/obj/item/toy/plush/P
	for(i=1, i<=scorned.len, i++)
		P = scorned[i]
		P.bad_news(src)
	scorned = null

	for(i=1, i<=scorned_by.len, i++)
		P = scorned_by[i]
		P.bad_news(src)
	scorned_by = null

	//null remaining lists
	squeak_override = null

	love_message = null
	partner_message = null
	heartbroken_message = null
	vowbroken_message = null
	parent_message = null

	return ..()

/obj/item/toy/plush/handle_atom_del(atom/A)
	if(A == grenade)
		grenade = null
	..()

/obj/item/toy/plush/attack_self(mob/user)
	. = ..()
	if(stuffed || grenade)
		to_chat(user, span_notice("You pet [src]. D'awww."))
		if(grenade && !grenade.active)
			log_game("[key_name(user)] activated a hidden grenade in [src].")
			grenade.preprime(user, msg = FALSE, volume = 10)
	else
		to_chat(user, span_notice("You try to pet [src], but it has no stuffing. Aww..."))

/obj/item/toy/plush/attackby(obj/item/I, mob/living/user, params)
	if(I.is_sharp())
		if(!grenade)
			if(!stuffed)
				to_chat(user, span_warning("You already murdered it!"))
				return
			if(!divine)
				user.visible_message(span_notice("[user] tears out the stuffing from [src]!"), span_notice("You rip a bunch of the stuffing from [src]. Murderer."))
				I.play_tool_sound(src)
				stuffed = FALSE
			else
				to_chat(user, span_warning("You can't bring yourself to tear the stuffing out of [src]!"))
		else
			to_chat(user, span_notice("You remove the grenade from [src]."))
			user.put_in_hands(grenade)
			grenade = null
		return
	if(istype(I, /obj/item/grenade))
		if(stuffed)
			to_chat(user, span_warning("You need to remove some stuffing first!"))
			return
		if(grenade)
			to_chat(user, span_warning("[src] already has a grenade!"))
			return
		if(!user.transferItemToLoc(I, src))
			return
		user.visible_message(span_warning("[user] slides [grenade] into [src]."), \
		span_danger("You slide [I] into [src]."))
		grenade = I
		var/turf/grenade_turf = get_turf(src)
		log_game("[key_name(user)] added a grenade ([I.name]) to [src] at [AREACOORD(grenade_turf)].")
		return
	if(istype(I, /obj/item/toy/plush))
		love(I, user)
		return
	return ..()

/obj/item/toy/plush/proc/love(obj/item/toy/plush/Kisser, mob/living/user)	//~<3
	var/chance = 100	//to steal a kiss, surely there's a 100% chance no-one would reject a plush such as I?
	var/concern = 20	//perhaps something might cloud true love with doubt
	var/loyalty = 30	//why should another get between us?
	var/duty = 50		//conquering another's is what I live for

	//we are not catholic
	if(young == TRUE || Kisser.young == TRUE)
		user.show_message(span_notice("[src] plays tag with [Kisser]."), MSG_VISUAL,
			span_notice("They're happy."), NONE)
		Kisser.cheer_up()
		cheer_up()

	//never again
	else if(Kisser in scorned)
		//message, visible, alternate message, neither visible nor audible
		user.show_message(span_notice("[src] rejects the advances of [Kisser]!"), MSG_VISUAL,
			span_notice("That didn't feel like it worked."), NONE)
	else if(src in Kisser.scorned)
		user.show_message(span_notice("[Kisser] realises who [src] is and turns away."), MSG_VISUAL,
			span_notice("That didn't feel like it worked."), NONE)

	//first comes love
	else if(Kisser.lover != src && Kisser.partner != src)	//cannot be lovers or married
		if(Kisser.lover)	//if the initiator has a lover
			Kisser.lover.heartbreak(Kisser)	//the old lover can get over the kiss-and-run whilst the kisser has some fun
			chance -= concern	//one heart already broken, what does another mean?
		if(lover)	//if the recipient has a lover
			chance -= loyalty	//mustn't... but those lips
		if(partner)	//if the recipient has a partner
			chance -= duty	//do we mate for life?

		if(prob(chance))	//did we bag a date?
			user.visible_message(span_notice("[user] makes [Kisser] kiss [src]!"),
									span_notice("You make [Kisser] kiss [src]!"))
			if(lover)	//who cares for the past, we live in the present
				lover.heartbreak(src)
			new_lover(Kisser)
			Kisser.new_lover(src)
		else
			user.show_message(span_notice("[src] rejects the advances of [Kisser], maybe next time?"), MSG_VISUAL,
								span_notice("That didn't feel like it worked, this time."), NONE)

	//then comes marriage
	else if(Kisser.lover == src && Kisser.partner != src)	//need to be lovers (assumes loving is a two way street) but not married (also assumes similar)
		user.visible_message(span_notice("[user] pronounces [Kisser] and [src] married! D'aw."),
									span_notice("You pronounce [Kisser] and [src] married!"))
		new_partner(Kisser)
		Kisser.new_partner(src)

	//then comes a baby in a baby's carriage, or an adoption in an adoption's orphanage
	else if(Kisser.partner == src && !plush_child)	//the one advancing does not take ownership of the child and we have a one child policy in the toyshop
		user.visible_message(span_notice("[user] is going to break [Kisser] and [src] by bashing them like that."),
									span_notice("[Kisser] passionately embraces [src] in your hands. Look away you perv!"))
		if(plop(Kisser))
			user.visible_message(span_notice("Something drops at the feet of [user]."),
							span_notice("The miracle of oh god did that just come out of [src]?!"))

	//then comes protection, or abstinence if we are catholic
	else if(Kisser.partner == src && plush_child)
		user.visible_message(span_notice("[user] makes [Kisser] nuzzle [src]!"),
									span_notice("You make [Kisser] nuzzle [src]!"))

	//then oh fuck something unexpected happened
	else
		user.show_message(span_warning("[Kisser] and [src] don't know what to do with one another."), NONE)

/obj/item/toy/plush/proc/heartbreak(obj/item/toy/plush/Brutus)
	if(lover != Brutus)
		to_chat(world, "lover != Brutus")
		return	//why are we considering someone we don't love?

	scorned.Add(Brutus)
	Brutus.scorned_by(src)

	lover = null
	Brutus.lover = null	//feeling's mutual

	heartbroken = TRUE
	mood_message = pick(heartbroken_message)

	if(partner == Brutus)	//oh dear...
		partner = null
		Brutus.partner = null	//it'd be weird otherwise
		vowbroken = TRUE
		mood_message = pick(vowbroken_message)

	update_desc()

/obj/item/toy/plush/proc/scorned_by(obj/item/toy/plush/Outmoded)
	scorned_by.Add(Outmoded)

/obj/item/toy/plush/proc/new_lover(obj/item/toy/plush/Juliet)
	if(lover == Juliet)
		return	//nice try
	lover = Juliet

	cheer_up()
	lover.cheer_up()

	mood_message = pick(love_message)
	update_desc()

	if(partner)	//who?
		partner = null	//more like who cares

/obj/item/toy/plush/proc/new_partner(obj/item/toy/plush/Apple_of_my_eye)
	if(partner == Apple_of_my_eye)
		return	//double marriage is just insecurity
	if(lover != Apple_of_my_eye)
		return	//union not born out of love will falter

	partner = Apple_of_my_eye

	heal_memories()
	partner.heal_memories()

	mood_message = pick(partner_message)
	update_desc()

/obj/item/toy/plush/proc/plop(obj/item/toy/plush/Daddy)
	if(partner != Daddy)
		return	FALSE //we do not have bastards in our toyshop

	if(is_type_in_typecache(Daddy, breeding_blacklist))
		return FALSE // some love is forbidden

	if(prob(50))	//it has my eyes
		plush_child = new type(get_turf(loc))
	else	//it has your eyes
		plush_child = new Daddy.type(get_turf(loc))

	plush_child.make_young(src, Daddy)

/obj/item/toy/plush/proc/make_young(obj/item/toy/plush/Mama, obj/item/toy/plush/Dada)
	if(Mama == Dada)
		return	//cloning is reserved for plants and spacemen

	maternal_parent = Mama
	paternal_parent = Dada
	young = TRUE
	name = "[Mama] Jr"	//Icelandic naming convention pending
	normal_desc = "[src] is a little baby of [maternal_parent] and [paternal_parent]!"	//original desc won't be used so the child can have moods
	update_desc()

	Mama.mood_message = pick(Mama.parent_message)
	Mama.update_desc()
	Dada.mood_message = pick(Dada.parent_message)
	Dada.update_desc()

/obj/item/toy/plush/proc/bad_news(obj/item/toy/plush/Deceased)	//cotton to cotton, sawdust to sawdust
	var/is_that_letter_for_me = FALSE
	if(partner == Deceased)	//covers marriage
		is_that_letter_for_me = TRUE
		partner = null
		lover = null
	else if(lover == Deceased)	//covers lovers
		is_that_letter_for_me = TRUE
		lover = null

	//covers children
	if(maternal_parent == Deceased)
		is_that_letter_for_me = TRUE
		maternal_parent = null

	if(paternal_parent == Deceased)
		is_that_letter_for_me = TRUE
		paternal_parent = null

	//covers parents
	if(plush_child == Deceased)
		is_that_letter_for_me = TRUE
		plush_child = null

	//covers bad memories
	if(Deceased in scorned)
		scorned.Remove(Deceased)
		cheer_up()	//what cold button eyes you have

	if(Deceased in scorned_by)
		scorned_by.Remove(Deceased)

	//all references to the departed should be cleaned up by now

	if(is_that_letter_for_me)
		heartbroken = TRUE
		mood_message = pick(heartbroken_message)
		update_desc()

/obj/item/toy/plush/proc/cheer_up()	//it'll be all right
	if(!heartbroken)
		return	//you cannot make smile what is already
	if(vowbroken)
		return	//it's a pretty big deal

	heartbroken = !heartbroken

	if(mood_message in heartbroken_message)
		mood_message = null
	update_desc()

/obj/item/toy/plush/proc/heal_memories()	//time fixes all wounds
	if(!vowbroken)
		vowbroken = !vowbroken
		if(mood_message in vowbroken_message)
			mood_message = null
	cheer_up()

/obj/item/toy/plush/update_desc()
	desc = normal_desc
	if(mood_message)
		desc += mood_message
	return ..()
/obj/item/toy/plush/carpplushie
	name = "space carp plushie"
	desc = "An adorable stuffed toy that resembles a space carp."
	icon_state = "carpplush"
	attack_verb_continuous = list("bites", "eats", "fin slaps")
	attack_verb_simple = list("bite", "eat", "fin slap")
	squeak_override = list('sound/weapons/bite.ogg' = 1)

/obj/item/toy/plush/bubbleplush
	name = "\improper Bubblegum plushie"
	desc = "The friendly red demon that gives good miners gifts."
	icon_state = "bubbleplush"
	attack_verb_continuous = list("rents")
	attack_verb_simple = list("rent")
	squeak_override = list('sound/magic/demon_attack1.ogg' = 1)

/obj/item/toy/plush/plushvar
	name = "\improper Ratvar plushie"
	desc = "An adorable plushie of the clockwork justiciar himself with new and improved spring arm action."
	icon_state = "plushvar"
	divine = TRUE
	var/obj/item/toy/plush/narplush/clash_target
	gender = MALE	//he's a boy, right?

/obj/item/toy/plush/plushvar/Moved()
	. = ..()
	if(clash_target)
		return
	var/obj/item/toy/plush/narplush/P = locate() in range(1, src)
	if(P && istype(P.loc, /turf/open) && !P.clashing)
		clash_of_the_plushies(P)

/obj/item/toy/plush/plushvar/proc/clash_of_the_plushies(obj/item/toy/plush/narplush/P)
	clash_target = P
	P.clashing = TRUE
	say("YOU.")
	P.say("Ratvar?!")
	var/obj/item/toy/plush/a_winnar_is
	var/victory_chance = 10
	for(var/i in 1 to 10) //We only fight ten times max
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(!Adjacent(P))
			visible_message(span_warning("The two plushies angrily flail at each other before giving up."))
			clash_target = null
			P.clashing = FALSE
			return
		playsound(src, 'sound/magic/clockwork/ratvar_attack.ogg', 50, TRUE, frequency = 2)
		sleep(2.4)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(prob(victory_chance))
			a_winnar_is = src
			break
		P.SpinAnimation(5, 0)
		sleep(5)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		playsound(P, 'sound/magic/clockwork/narsie_attack.ogg', 50, TRUE, frequency = 2)
		sleep(3.3)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(prob(victory_chance))
			a_winnar_is = P
			break
		SpinAnimation(5, 0)
		victory_chance += 10
		sleep(5)
	if(!a_winnar_is)
		a_winnar_is = pick(src, P)
	if(a_winnar_is == src)
		say(pick("DIE.", "ROT."))
		P.say(pick("Nooooo...", "Not die. To y-", "Die. Ratv-", "Sas tyen re-"))
		playsound(src, 'sound/magic/clockwork/anima_fragment_attack.ogg', 50, TRUE, frequency = 2)
		playsound(P, 'sound/magic/demon_dies.ogg', 50, TRUE, frequency = 2)
		explosion(P, 0, 0, 1, holy = TRUE)
		qdel(P)
		clash_target = null
	else
		say("NO! I will not be banished again...")
		P.say(pick("Ha.", "Ra'sha fonn dest.", "You fool. To come here."))
		playsound(src, 'sound/magic/clockwork/anima_fragment_death.ogg', 62, TRUE, frequency = 2)
		playsound(P, 'sound/magic/demon_attack1.ogg', 50, TRUE, frequency = 2)
		explosion(src, 0, 0, 1, holy = TRUE)
		qdel(src)
		P.clashing = FALSE

/obj/item/toy/plush/narplush
	name = "\improper Nar'Sie plushie"
	desc = "A small stuffed doll of the elder goddess Nar'Sie. Who thought this was a good children's toy?"
	icon_state = "narplush"
	divine = TRUE
	var/clashing
	var/invoker_charges = 2
	gender = FEMALE	//it's canon if the toy is

/obj/item/toy/plush/narplush/examine(mob/user)
	. = ..()
	if(invoker_charges == 0)
		. += span_notice("She looks tired.")
		return
	if(IS_CULTIST(user))
		. += span_warning("She has [invoker_charges] [invoker_charges == 1 ? "charge" : "charges"] left!")

/obj/item/toy/plush/narplush/Moved()
	. = ..()
	var/obj/item/toy/plush/plushvar/P = locate() in range(1, src)
	if(P && istype(P.loc, /turf/open) && !P.clash_target && !clashing)
		P.clash_of_the_plushies(src)

/obj/item/toy/plush/narplush/hugbox
	invoker_charges = 0

/obj/item/toy/plush/lizard_plushie
	name = "lizard plushie"
	desc = "An adorable stuffed toy that resembles a lizardperson."
	icon_state = "map_plushie_lizard"
	greyscale_config = /datum/greyscale_config/plush_lizard
	attack_verb_continuous = list("claws", "hisses", "tail slaps")
	attack_verb_simple = list("claw", "hiss", "tail slap")
	squeak_override = list('sound/weapons/slash.ogg' = 1)
	flags_1 = IS_PLAYER_COLORABLE_1

/obj/item/toy/plush/lizard_plushie/Initialize(mapload)
	. = ..()
	if(!greyscale_colors)
		// Generate a random valid lizard color for our plushie friend
		var/generated_lizard_color = "#" + random_color()
		var/temp_hsv = RGBtoHSV(generated_lizard_color)

		// If our color is too dark, use the classic green lizard plush color
		if(ReadHSV(temp_hsv)[3] < ReadHSV("#7F7F7F")[3])
			generated_lizard_color = "#66ff33"

		// Set our greyscale colors to the lizard color we made + black eyes
		set_greyscale(colors = list(generated_lizard_color, "#000000"))

// Preset lizard plushie that uses the original lizard plush green. (Or close to it)
/obj/item/toy/plush/lizard_plushie/green
	desc = "An adorable stuffed toy that resembles a green lizardperson. This one fills you with nostalgia and soul."
	greyscale_colors = "#66ff33#000000"

/obj/item/toy/plush/lizard_plushie/space
	name = "space lizard plushie"
	desc = "An adorable stuffed toy that resembles a very determined spacefaring lizardperson. To infinity and beyond, little guy."
	icon_state = "map_plushie_spacelizard"
	greyscale_config = /datum/greyscale_config/plush_spacelizard
	// space lizards can't hit people with their tail, it's stuck in their suit
	attack_verb_continuous = list("claws", "hisses", "bops")
	attack_verb_simple = list("claw", "hiss", "bops")

/obj/item/toy/plush/lizard_plushie/space/green
	desc = "An adorable stuffed toy that resembles a very determined spacefaring green lizardperson. To infinity and beyond, little guy. This one fills you with nostalgia and soul."
	greyscale_colors = "#66ff33#000000"

/obj/item/toy/plush/snakeplushie
	name = "snake plushie"
	desc = "An adorable stuffed toy that resembles a snake. Not to be mistaken for the real thing."
	icon_state = "snakeplush"
	attack_verb_continuous = list("bites", "hisses", "tail slaps")
	attack_verb_simple = list("bite", "hiss", "tail slap")
	squeak_override = list('sound/weapons/bite.ogg' = 1)

/obj/item/toy/plush/nukeplushie
	name = "operative plushie"
	desc = "A stuffed toy that resembles a syndicate nuclear operative. The tag claims operatives to be purely fictitious."
	icon_state = "nukeplush"
	attack_verb_continuous = list("shoots", "nukes", "detonates")
	attack_verb_simple = list("shoot", "nuke", "detonate")
	squeak_override = list('sound/effects/hit_punch.ogg' = 1)

/obj/item/toy/plush/slimeplushie
	name = "slime plushie"
	desc = "An adorable stuffed toy that resembles a purple slime. It is practically just a hacky sack."
	icon_state = "slimeplush"
	attack_verb_continuous = list("blorbles", "slimes", "absorbs")
	attack_verb_simple = list("blorble", "slime", "absorb")
	squeak_override = list('sound/effects/blobattack.ogg' = 1)
	gender = FEMALE	//given all the jokes and drawings, I'm not sure the xenobiologists would make a slimeboy
	/// Most of the following is just stolen from the moth plush code for the slimes
	var/suicide_count = 0

/obj/item/toy/plush/slimeplushie/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] puts [src] on top of their head. The plush begins to consume [user.p_their()] very essence! It looks like [user.p_theyre()] trying to commit suicide!"))
	suicide_count++
	if(suicide_count < 3)
		desc = "An unsettling slime plushie. After killing [suicide_count] [suicide_count == 1 ? "person" : "people"] it ressembles a level 5 biohazard..."
	else
		desc = "A creepy slime plushie. It has killed [suicide_count] people! I don't think I want to hug it any more!"
		divine = TRUE
		resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	playsound(src, 'sound/effects/blobattack.ogg', 100, TRUE, -1)
	var/list/available_spots = get_adjacent_open_turfs(loc)
	if(available_spots.len) //If the user is in a confined space the plushie will drop normally as the user dies, but in the open the plush is placed one tile away from the user to prevent squeak spam
		var/turf/open/random_open_spot = pick(available_spots)
		forceMove(random_open_spot)
	user.dust(just_ash = FALSE, drop_items = TRUE)
	return MANUAL_SUICIDE

/obj/item/toy/plush/slimeplushie/random
	name = "\improper Random Slimeplush"
	icon_state = "slimeplush"
	desc = "An undefined slime plushie. It looks like but isn't a normal slime plushie! (if you see this, contact an upper being as soon as possible)."
	item_flags = ABSTRACT

/obj/item/toy/plush/slimeplushie/random/Initialize(mapload)
	. = ..()
	var sloime_type = pick(subtypesof(/obj/item/toy/plush/slimeplushie) - /obj/item/toy/plush/slimeplushie/random/)
	new sloime_type(loc)
	return INITIALIZE_HINT_QDEL

/obj/item/toy/plush/slimeplushie/pink
	name = "pink slime plushie"
	desc = "An adorable stuffed toy that resembles a pink slime. It is practically just a hacky sack. It looks happy!"
	icon_state = "slimeplush_pink"

/obj/item/toy/plush/slimeplushie/green
	name = "green slime plushie"
	desc = "An adorable stuffed toy that resembles a green slime. It is practically just a hacky sack. It looks grossed out..."
	icon_state = "slimeplush_green"

/obj/item/toy/plush/slimeplushie/blue
	name = "blue slime plushie"
	desc = "An adorable stuffed toy that resembles a blue slime. It is practically just a hacky sack. It looks a bit sad."
	icon_state = "slimeplush_blue"

/obj/item/toy/plush/slimeplushie/red
	name = "red slime plushie"
	desc = "An adorable stuffed toy that resembles a red slime. It is practically just a hacky sack. It looks mischivious!"
	icon_state = "slimeplush_red"

/obj/item/toy/plush/slimeplushie/rainbow
	name = "rainbow slime plushie"
	desc = "An adorable stuffed toy that resembles a rainbow slime. It is practically just a hacky sack. It looks very colorful!"
	icon_state = "slimeplush_rainbow"

/obj/item/toy/plush/awakenedplushie
	name = "awakened plushie"
	desc = "An ancient plushie that has grown enlightened to the true nature of reality."
	icon_state = "awakeplush"

/obj/item/toy/plush/awakenedplushie/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/edit_complainer)

/obj/item/toy/plush/beeplushie
	name = "bee plushie"
	desc = "A cute toy that resembles an even cuter bee."
	icon_state = "beeplush"
	attack_verb_continuous = list("stings")
	attack_verb_simple = list("sting")
	gender = FEMALE
	squeak_override = list('sound/voice/moth/scream_moth.ogg' = 1)

/obj/item/toy/plush/rouny
	name = "runner plushie"
	desc = "A plushie depicting a xenomorph runner, made to commemorate the centenary of the Battle of LV-426. Much cuddlier than the real thing."
	icon_state = "rounyplush"
	attack_verb_continuous = list("slashes", "bites", "charges")
	attack_verb_simple = list("slash", "bite", "charge")
	squeak_override = list('sound/weapons/bite.ogg' = 1)

/obj/item/toy/plush/moth
	name = "moth plushie"
	desc = "An adorable mothperson plushie. It's a huggable bug!"
	icon_state = "moffplush"
	attack_verb_continuous = list("flutters", "flaps")
	attack_verb_simple = list("flutter", "flap")
	squeak_override = list('sound/voice/moth/scream_moth.ogg' = 1)
///Used to track how many people killed themselves with item/toy/plush/moth
	var/suicide_count = 0

/obj/item/toy/plush/moth/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] stares deeply into the eyes of [src]. The plush begins to consume [user.p_their()] soul!  It looks like [user.p_theyre()] trying to commit suicide!"))
	suicide_count++
	if(suicide_count < 3)
		desc = "An unsettling mothperson plushie. After killing [suicide_count] [suicide_count == 1 ? "person" : "people"] it's not looking so huggable now..."
	else
		desc = "A creepy mothperson plushie. It has killed [suicide_count] people! I don't think I want to hug it any more!"
		divine = TRUE
		resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	playsound(src, 'sound/hallucinations/wail.ogg', 50, TRUE, -1)
	var/list/available_spots = get_adjacent_open_turfs(loc)
	if(available_spots.len) //If the user is in a confined space the plushie will drop normally as the user dies, but in the open the plush is placed one tile away from the user to prevent squeak spam
		var/turf/open/random_open_spot = pick(available_spots)
		forceMove(random_open_spot)
	user.dust(just_ash = FALSE, drop_items = TRUE)
	return MANUAL_SUICIDE

/obj/item/toy/plush/moth/random
	name = "\improper Random Mothplush"
	icon_state = "moffplush_random"
	desc = "An undefined mothperson plushie. It's a debuggable bug! (if you see this, contact an upper beign as soon as possible)."
	item_flags = ABSTRACT

/obj/item/toy/plush/moth/random/Initialize(mapload)
	. = ..()
	var moff_type = pick(subtypesof(/obj/item/toy/plush/moth) - /obj/item/toy/plush/moth/random/)
	new moff_type(loc)
	return INITIALIZE_HINT_QDEL

/obj/item/toy/plush/moth/monarch
	name = "monarch moth plushie"
	desc = "An adorable mothperson plushie. It's an important bug!"
	icon_state = "moffplush_monarch"

/obj/item/toy/plush/moth/luna
	name = "luna moth plushie"
	desc = "An adorable mothperson plushie. It's a lunar bug!"
	icon_state = "moffplush_luna"

/obj/item/toy/plush/moth/atlas
	name = "atlas moth plushie"
	desc = "An adorable mothperson plushie. It's a wide bug!"
	icon_state = "moffplush_atlas"

/obj/item/toy/plush/moth/redish
	name = "redish moth plushie"
	desc = "An adorable mothperson plushie. It's a red bug!"
	icon_state = "moffplush_redish"

/obj/item/toy/plush/moth/royal
	name = "royal moth plushie"
	desc = "An adorable mothperson plushie. It's a royal bug!"
	icon_state = "moffplush_royal"

/obj/item/toy/plush/moth/gothic
	name = "gothic moth plushie"
	desc = "An adorable mothperson plushie. It's a dark bug!"
	icon_state = "moffplush_gothic"

/obj/item/toy/plush/moth/lovers
	name = "lovers moth plushie"
	desc = "An adorable mothperson plushie. It's a loveley bug!"
	icon_state = "moffplush_lovers"

/obj/item/toy/plush/moth/whitefly
	name = "whitefly moth plushie"
	desc = "An adorable mothperson plushie. It's a shy bug!"
	icon_state = "moffplush_whitefly"

/obj/item/toy/plush/moth/punished
	name = "punished moth plushie"
	desc = "An adorable mothperson plushie. It's a sad bug... that's quite sad actualy."
	icon_state = "moffplush_punished"

/obj/item/toy/plush/moth/firewatch
	name = "firewatch moth plushie"
	desc = "An adorable mothperson plushie. It's a firey bug!"
	icon_state = "moffplush_firewatch"

/obj/item/toy/plush/moth/deadhead
	name = "deadhead moth plushie"
	desc = "An adorable mothperson plushie. It's a silent bug!"
	icon_state = "moffplush_deadhead"

/obj/item/toy/plush/moth/poison
	name = "poison moth plushie"
	desc = "An adorable mothperson plushie. It's a toxic bug!"
	icon_state = "moffplush_poison"

/obj/item/toy/plush/moth/ragged
	name = "ragged moth plushie"
	desc = "An adorable mothperson plushie. It's a robust bug!"
	icon_state = "moffplush_ragged"

/obj/item/toy/plush/moth/snow
	name = "snow moth plushie"
	desc = "An adorable mothperson plushie. It's a cool bug!"
	icon_state = "moffplush_snow"

/obj/item/toy/plush/moth/clockwork
	name = "clockwork moth plushie"
	desc = "An adorable mothperson plushie. It's a precise bug!"
	icon_state = "moffplush_clockwork"

/obj/item/toy/plush/moth/moonfly
	name = "moonfly moth plushie"
	desc = "An adorable mothperson plushie. It's a nightly bug!"
	icon_state = "moffplush_moonfly"

/obj/item/toy/plush/moth/witchwing
	name = "witchwing moth plushie"
	desc = "An adorable mothperson plushie. It's an enchanted bug!"
	icon_state = "moffplush_witchwing"

/obj/item/toy/plush/moth/bluespace
	name = "bluespace moth plushie"
	desc = "An adorable mothperson plushie. It's a teleporting bug!"
	icon_state = "moffplush_bluespace"

/obj/item/toy/plush/moth/plasmafire
	name = "plasmafire moth plushie"
	desc = "An adorable mothperson plushie. It's a plasma bug!"
	icon_state = "moffplush_plasmafire"

/obj/item/toy/plush/moth/brown
	name = "brown moth plushie"
	desc = "An adorable mothperson plushie. It's a brown bug!"
	icon_state = "moffplush_brown"

/obj/item/toy/plush/moth/rosy
	name = "rosy moth plushie"
	desc = "An adorable mothperson plushie. It's a cute bug!"
	icon_state = "moffplush_rosy"

/obj/item/toy/plush/moth/error
	name = "error moth plushie"
	desc = "An adorable mothperson plushie. It's a debuggable bug!"
	icon_state = "moffplush_random"

/obj/item/toy/plush/moth/rainbow
	name = "rainbow moth plushie"
	desc = "An adorable mothperson plushie. It's a colorful bug!"
	icon_state = "moffplush_rainbow"

/obj/item/toy/plush/crossed
	name = "ghost plushie"
	desc = "It reminds you of someone important, you just can't make out who."
	icon_state = "crossedplush"
	squeak_override = list('sound/items/haunted/ghostitemattack.ogg' = 1)

/obj/item/toy/plush/runtime
	name = "Runtime plushie"
	desc = "GPLUSH."
	icon_state = "runtimeplush"
	squeak_override = list('sound/effects/meow1.ogg' = 1)

/obj/item/toy/plush/gondola
	name = "gondola plushie"
	desc = "The silent walker, in plush form."
	icon_state = "gondolaplush"
	squeak_override = list('sound/misc/null.ogg' = 1)

/obj/item/toy/plush/flushed
	name = "flushed plushie"
	desc = "Hgrgrhrhg cute."
	icon_state = "flushplush"

/obj/item/toy/plush/shark
	name = "shark plushie"
	desc = "A big plushie depicting a rather cartoonish, yet cute shark. The tag calls it a 'søthai', noting that it was made by an obscure furniture manufacturer in Scandinavia."
	lefthand_file = 'icons/mob/inhands/plushes_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/plushes_righthand.dmi'
	icon_state = "cuteswedishsharkplush"
	squeak_override = list('sound/weapons/bite.ogg' = 1)

/obj/item/toy/plush/shark/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "big_plush", /datum/mood_event/bigplush, src)

/obj/item/toy/plush/shark/dropped(mob/living/carbon/user)
	..()
	SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "big_plush")

/obj/item/toy/plush/flushed/rainbow
	name = "rainbow flushed plushie"
	desc = "Hgrgrhrhg cuter."
	icon_state = "flushplush_rainbow"

/obj/item/choice_beacon/radial/plushie
	name = "plushie delivery beacon"
	desc = "Summon your new friend!"
	icon_state = "gangtool-plushie"
	var/static/list/plushie_list = list(
		/obj/item/toy/plush/bubbleplush,
		/obj/item/toy/plush/carpplushie,
		/obj/item/toy/plush/snakeplushie,
		/obj/item/toy/plush/lizard_plushie,
		/obj/item/toy/plush/slimeplushie,
		/obj/item/toy/plush/slimeplushie/pink,
		/obj/item/toy/plush/slimeplushie/green,
		/obj/item/toy/plush/slimeplushie/blue,
		/obj/item/toy/plush/slimeplushie/red,
		/obj/item/toy/plush/slimeplushie/rainbow,
		/obj/item/toy/plush/nukeplushie,
		/obj/item/toy/plush/awakenedplushie,
		/obj/item/toy/plush/beeplushie,
		/obj/item/toy/plush/crossed,
		/obj/item/toy/plush/rouny,
		/obj/item/toy/plush/runtime,
		/obj/item/toy/plush/flushed,
		/obj/item/toy/plush/flushed/rainbow,
		/obj/item/toy/plush/gondola,
		/obj/item/toy/plush/moth/atlas,
		/obj/item/toy/plush/moth/bluespace,
		/obj/item/toy/plush/moth/brown,
		/obj/item/toy/plush/moth/clockwork,
		/obj/item/toy/plush/moth/deadhead,
		/obj/item/toy/plush/moth/firewatch,
		/obj/item/toy/plush/moth/gothic,
		/obj/item/toy/plush/moth/lovers,
		/obj/item/toy/plush/moth/luna,
		/obj/item/toy/plush/moth/monarch,
		/obj/item/toy/plush/moth/moonfly,
		/obj/item/toy/plush/moth/plasmafire,
		/obj/item/toy/plush/moth/poison,
		/obj/item/toy/plush/moth/punished,
		/obj/item/toy/plush/moth/ragged,
		/obj/item/toy/plush/moth/rainbow,
		/obj/item/toy/plush/moth/redish,
		/obj/item/toy/plush/moth/rosy,
		/obj/item/toy/plush/moth/royal,
		/obj/item/toy/plush/moth/snow,
		/obj/item/toy/plush/moth/whitefly,
		/obj/item/toy/plush/moth/witchwing,
		/obj/item/toy/plush/shark,
	)

/obj/item/choice_beacon/radial/plushie/generate_options(mob/living/M)
	var/list/item_list = generate_item_list()
	if(!length(item_list))
		return
	var/choice = show_radial_menu(M, src, item_list, radius = 36, require_near = TRUE)
	if(!QDELETED(src) && !(isnull(choice)) && !M.incapacitated() && in_range(M,src))
		for(var/V in plushie_list)
			var/atom/A = V
			if(initial(A.name) == choice)
				spawn_option(A,M)
				uses--
				if(!uses)
					qdel(src)
				else
					balloon_alert(M, "[uses] use[uses > 1 ? "s" : ""] remaining")
					to_chat(M, span_notice("[uses] use[uses > 1 ? "s" : ""] remaining on the [src]."))
				return

/obj/item/choice_beacon/radial/plushie/generate_item_list()
	var/static/list/item_list
	if(!item_list)
		item_list = list()
		for(var/obj/item/toy/plush/I as() in plushie_list)
			var/image/plushie_icon = image(initial(I.icon), initial(I.icon_state))
			var/datum/radial_menu_choice/choice = new
			choice.image = plushie_icon
			item_list[initial(I.name)] = choice
	return item_list

/////////////////
//DONATOR ITEMS//
/////////////////

/obj/item/toy/plush/ian
	name = "ian plushie"
	desc = "Keep him by your side."
	icon_state = "ianplush"

/obj/item/toy/plush/lisa
	name = "lisa plushie"
	desc = "Keep her by your side."
	icon_state = "lisaplush"

/obj/item/toy/plush/renault
	name = "renault plushie"
	desc = "AWOOOO!"
	icon_state = "renaultplush"

/obj/item/toy/plush/opa
	name = "metal upa"
	desc = "You feel like this could have prevented World War 3 in a parallel timeline."
	icon_state = "upaplush"
