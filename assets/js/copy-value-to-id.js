/*global AwesompleteUtil*/

const copyValueToId = (node) => {
    const a = node.getAttribute.bind(node)
    , dataField = a('dataField')
    , field = a('field')
    , targetField = a('targetField')
    , target = a('target')
    if (field == null) throw new Error("Missing field attribute.")  // null or undefined
    if (target == null && targetField == null) throw new Error("Missing target or targetField attribute.")
    AwesompleteUtil.startCopy('#' + field, dataField, targetField ? '#' + targetField : target)
}

export default copyValueToId