pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell

/**
 * Hand-picked accent colours layered on top of the generated Material palette.
 *
 * The generated palette comes from a single seed colour run through Material
 * You, so the accent roles cannot be chosen individually. This keeps the last
 * generated values around and re-derives m3colors from them, which means an
 * override can be cleared and the generated colour comes straight back without
 * waiting for a wallpaper regeneration.
 *
 * Only the three accent roles are overridable, on purpose: surface and
 * background feed the dark/light detection in MaterialThemeLoader, so letting
 * them be overridden would flip the whole theme as a side effect.
 */
Singleton {
    id: root

    // `key` is the config.json key, `role` the Material role it drives. They
    // differ for foreground colours because QML reads a property named
    // on<Uppercase> as a signal handler, so config cannot spell them "onPrimary".
    readonly property var roleGroups: [
        {
            title: "Primary",
            slots: [
                { key: "primary", role: "primary" },
                { key: "primaryText", role: "onPrimary" },
                { key: "primaryContainer", role: "primaryContainer" },
                { key: "primaryContainerText", role: "onPrimaryContainer" }
            ]
        },
        {
            title: "Secondary",
            slots: [
                { key: "secondary", role: "secondary" },
                { key: "secondaryText", role: "onSecondary" },
                { key: "secondaryContainer", role: "secondaryContainer" },
                { key: "secondaryContainerText", role: "onSecondaryContainer" }
            ]
        },
        {
            title: "Tertiary",
            slots: [
                { key: "tertiary", role: "tertiary" },
                { key: "tertiaryText", role: "onTertiary" },
                { key: "tertiaryContainer", role: "tertiaryContainer" },
                { key: "tertiaryContainerText", role: "onTertiaryContainer" }
            ]
        }
    ]
    readonly property var variantLabels: ["Base", "Text", "Container", "Container text"]

    readonly property var slots: {
        let flat = [];
        for (let i = 0; i < root.roleGroups.length; i++) {
            const groupSlots = root.roleGroups[i].slots;
            for (let j = 0; j < groupSlots.length; j++) flat.push(groupSlots[j]);
        }
        return flat;
    }

    // Last palette handed over by MaterialThemeLoader, keys in camelCase.
    // Overrides are resolved against this rather than against m3colors, which
    // already has the previous round of overrides baked into it.
    property var generated: null

    // Single reactive view of the configured overrides. Reading the config
    // properties inside a binding is what registers them as dependencies, so
    // editing or clearing a slot in the settings app takes effect immediately
    // instead of waiting for the next palette regeneration.
    readonly property var overrideMap: {
        const options = Config.options?.appearance?.palette?.overrides;
        let map = ({ enable: options?.enable ?? false });
        for (let i = 0; i < root.slots.length; i++) {
            const key = root.slots[i].key;
            const value = options?.[key] ?? "";
            map[key] = root.isValidHex(value) ? value : "";
        }
        return map;
    }
    onOverrideMapChanged: root.apply()

    // MaterialThemeLoader prefixes the camelCased theme key as-is, so the
    // properties are m3primary / m3onPrimary -- no capitalisation of the role.
    function m3Key(role) {
        return "m3" + role;
    }

    function isValidHex(value) {
        return typeof value === "string" && /^#[0-9A-Fa-f]{6}$/.test(value);
    }

    /**
     * The override set for a slot, or "" when the generated colour is in use.
     */
    function overrideFor(key) {
        return root.overrideMap[key] ?? "";
    }

    /**
     * The colour a slot ends up with: the override when one is set and
     * overriding is enabled, otherwise whatever was generated.
     */
    function colorFor(key, role) {
        if (root.overrideMap.enable && root.overrideMap[key]) return root.overrideMap[key];
        const generatedColor = root.generated?.[role];
        if (generatedColor) return generatedColor;
        // Before the first palette load there is nothing to fall back to but
        // m3colors, and nothing at all while a delegate is still being built.
        return Appearance.m3colors[root.m3Key(role)] ?? "transparent";
    }

    function setOverride(key, hex) {
        Config.options.appearance.palette.overrides[key] = root.isValidHex(hex) ? hex : "";
    }

    function clearAll() {
        for (let i = 0; i < root.slots.length; i++) {
            Config.options.appearance.palette.overrides[root.slots[i].key] = "";
        }
    }

    readonly property bool hasAnyOverride: {
        for (let i = 0; i < root.slots.length; i++) {
            if (root.overrideMap[root.slots[i].key]) return true;
        }
        return false;
    }

    /**
     * Called by MaterialThemeLoader once a freshly generated palette has been
     * pushed into m3colors. `json` is the raw generated theme, snake_case keys.
     */
    function setSource(json) {
        let camelCased = ({});
        for (const jsonKey in json) {
            if (!json.hasOwnProperty(jsonKey)) continue;
            camelCased[jsonKey.replace(/_([a-z])/g, (g) => g[1].toUpperCase())] = json[jsonKey];
        }
        root.generated = camelCased;
        root.apply();
    }

    function apply() {
        if (!root.generated) return;
        for (let i = 0; i < root.slots.length; i++) {
            const slot = root.slots[i];
            const key = root.m3Key(slot.role);
            // Guard against a role the palette does not declare: m3colors is a
            // QtObject, so assigning an unknown key would fail silently.
            if (Appearance.m3colors[key] === undefined) continue;
            Appearance.m3colors[key] = root.colorFor(slot.key, slot.role);
        }
    }
}
