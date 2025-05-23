#define ENGINE_UNWRENCHED 0
#define ENGINE_WRENCHED 1
#define ENGINE_WELDED 2
#define ENGINE_WELDTIME 200

/obj/structure/shuttle
	name = "shuttle"
	icon = 'icons/turf/shuttle.dmi'
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	max_integrity = 500
	armor_type = /datum/armor/structure_shuttle


/datum/armor/structure_shuttle
	melee = 100
	bullet = 10
	laser = 10
	fire = 50
	acid = 70

/obj/structure/shuttle/engine
	name = "engine"
	desc = "A bluespace engine used to make shuttles move."
	density = TRUE
	anchored = TRUE
	z_flags = Z_BLOCK_IN_DOWN | Z_BLOCK_IN_UP
	can_atmos_pass = ATMOS_PASS_DENSITY
	var/engine_power = 1
	var/state = ENGINE_WELDED //welding shmelding

/obj/structure/shuttle/engine/Initialize(mapload)
	. = ..()
	if(anchored && state == ENGINE_UNWRENCHED)
		state = ENGINE_WRENCHED

//Ugh this is a lot of copypasta from emitters, welding need some boilerplate reduction
/obj/structure/shuttle/engine/can_be_unfasten_wrench(mob/user, silent)
	if(state == ENGINE_WELDED)
		if(!silent)
			to_chat(user, span_warning("[src] is welded to the floor!"))
		return FAILED_UNFASTEN
	return ..()

/obj/structure/shuttle/engine/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		if(anchored)
			state = ENGINE_WRENCHED
		else
			state = ENGINE_UNWRENCHED

/obj/structure/shuttle/engine/wrench_act(mob/living/user, obj/item/I)
	default_unfasten_wrench(user, I)
	return TRUE

/obj/structure/shuttle/engine/welder_act(mob/living/user, obj/item/I)
	switch(state)
		if(ENGINE_UNWRENCHED)
			to_chat(user, span_warning("The [src.name] needs to be wrenched to the floor!"))
		if(ENGINE_WRENCHED)
			if(!I.tool_start_check(user, amount=0))
				return TRUE

			user.visible_message("[user.name] starts to weld the [name] to the floor.", \
				span_notice("You start to weld \the [src] to the floor..."), \
				span_italics("You hear welding."))

			if(I.use_tool(src, user, ENGINE_WELDTIME, volume=50))
				state = ENGINE_WELDED
				to_chat(user, span_notice("You weld \the [src] to the floor."))
				alter_engine_power(engine_power)

		if(ENGINE_WELDED)
			if(!I.tool_start_check(user, amount=0))
				return TRUE

			user.visible_message("[user.name] starts to cut the [name] free from the floor.", \
				span_notice("You start to cut \the [src] free from the floor..."), \
				span_italics("You hear welding."))

			if(I.use_tool(src, user, ENGINE_WELDTIME, volume=50))
				state = ENGINE_WRENCHED
				to_chat(user, span_notice("You cut \the [src] free from the floor."))
				alter_engine_power(-engine_power)
	return TRUE

/obj/structure/shuttle/engine/Destroy()
	if(state == ENGINE_WELDED)
		alter_engine_power(-engine_power)
	. = ..()

//Propagates the change to the shuttle.
/obj/structure/shuttle/engine/proc/alter_engine_power(mod)
	if(mod == 0)
		return
	if(SSshuttle.is_in_shuttle_bounds(src))
		var/obj/docking_port/mobile/M = SSshuttle.get_containing_shuttle(src)
		if(M)
			M.alter_engines(mod)

/obj/structure/shuttle/engine/heater
	name = "engine heater"
	icon_state = "heater"
	desc = "Directs energy into compressed particles in order to power engines."
	engine_power = 0 // todo make these into 2x1 parts

/obj/structure/shuttle/engine/platform
	name = "engine platform"
	icon_state = "platform"
	desc = "A platform for engine components."
	engine_power = 0

/obj/structure/shuttle/engine/propulsion
	name = "propulsion engine"
	icon_state = "propulsion"
	desc = "A standard reliable bluespace engine used by many forms of shuttles."
	opacity = TRUE

/obj/structure/shuttle/engine/propulsion/left
	name = "left propulsion engine"
	icon_state = "propulsion_l"

/obj/structure/shuttle/engine/propulsion/right
	name = "right propulsion engine"
	icon_state = "propulsion_r"

/obj/structure/shuttle/engine/propulsion/burst
	name = "burst engine"
	desc = "An engine that releases a large bluespace burst to propel it."

/obj/structure/shuttle/engine/propulsion/burst/cargo
	state = ENGINE_UNWRENCHED
	anchored = FALSE

/obj/structure/shuttle/engine/propulsion/burst/left
	name = "left burst engine"
	icon_state = "burst_l"

/obj/structure/shuttle/engine/propulsion/burst/right
	name = "right burst engine"
	icon_state = "burst_r"

/obj/structure/shuttle/engine/router
	name = "engine router"
	icon_state = "router"
	desc = "Redirects around energized particles in engine structures."

/obj/structure/shuttle/engine/large
	name = "engine"
	opacity = TRUE
	icon = 'icons/obj/2x2.dmi'
	icon_state = "large_engine"
	desc = "A very large bluespace engine used to propel very large ships."
	bound_width = 64
	bound_height = 64
	appearance_flags = LONG_GLIDE

/obj/structure/shuttle/engine/large/chopped
	icon = 'icons/obj/engine_chopped.dmi'
	icon_state = "top_left_smaller"
	opacity = FALSE
	bound_width = 32
	bound_height = 32

/obj/structure/shuttle/engine/large/chopped/top_left
	icon_state = "top_left_smaller"

/obj/structure/shuttle/engine/large/chopped/top_right
	icon_state = "top_right_smaller"

/obj/structure/shuttle/engine/large/chopped/bottom_left
	icon_state = "bottom_left_smaller"

/obj/structure/shuttle/engine/large/chopped/bottom_right
	icon_state = "bottom_right_smaller"

/obj/structure/shuttle/engine/huge
	name = "engine"
	opacity = TRUE
	icon = 'icons/obj/3x3.dmi'
	icon_state = "huge_engine"
	desc = "An extremely large bluespace engine used to propel extremely large ships."
	bound_width = 96
	bound_height = 96
	appearance_flags = LONG_GLIDE

/obj/structure/shuttle/engine/huge/chopped
	icon = 'icons/obj/engine_chopped.dmi'
	icon_state = "top_left"
	opacity = FALSE
	bound_width = 32
	bound_height = 32

/obj/structure/shuttle/engine/huge/chopped/top_left
	icon_state = "top_left"

/obj/structure/shuttle/engine/huge/chopped/top_center
	icon_state = "top_center"

/obj/structure/shuttle/engine/huge/chopped/top_right
	icon_state = "top_right"

/obj/structure/shuttle/engine/huge/chopped/center_left
	icon_state = "center_left"

/obj/structure/shuttle/engine/huge/chopped/center_center
	icon_state = "center_center"

/obj/structure/shuttle/engine/huge/chopped/center_right
	icon_state = "center_right"

/obj/structure/shuttle/engine/huge/chopped/bottom_left
	icon_state = "bottom_left"

/obj/structure/shuttle/engine/huge/chopped/bottom_center
	icon_state = "bottom_center"

/obj/structure/shuttle/engine/huge/chopped/bottom_right
	icon_state = "bottom_right"

/obj/structure/shuttle/engine/hugeionengine
	name = "Nanotrasen MkIII BPDT engine"
	icon = 'icons/obj/4x7.dmi'
	icon_state = "huge_ion_engine"
	desc = "An extremely large bluespace-plasmadynamic ion engine used to propel objects reaching the size of stations."
	bound_width = 128
	bound_height = 224
	appearance_flags = NONE

/obj/structure/shuttle/engine/hugeionafterburn
	name = "Nanotrasen MkIII BPDT engine afterburner"
	opacity = 1
	icon = 'icons/obj/4x7.dmi'
	icon_state = "huge_ion_afterburn"
	desc = "Quite hot, don't get too close to the glowing end!"
	bound_width = 128
	bound_height = 224
	appearance_flags = NONE

#undef ENGINE_UNWRENCHED
#undef ENGINE_WRENCHED
#undef ENGINE_WELDED
#undef ENGINE_WELDTIME
